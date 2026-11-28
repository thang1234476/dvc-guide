# tthc_rag.py - Truy xuất (FAISS + BM25 + RRF + Reranker), cập nhật dữ liệu tức thì, kiểm tra sau khi sinh.
import os, re, json, time, shutil, hashlib, threading
from copy import deepcopy
from collections import defaultdict
import numpy as np
from app.services import variants as tthc_variants
from app.services.procedure_sections import supplemental_sections

EMB_NAME, RERANK_NAME = 'BAAI/bge-m3', 'BAAI/bge-reranker-v2-m3'
M_CHUNKS, RRF_K = 50, 60
MAX_CHARS = 1500
GENERAL = {'Tên thủ tục', 'Lĩnh vực', 'Cơ quan thực hiện', 'Đối tượng', 'Kết quả'}


# ---------- Chia đoạn: GIỐNG HỆT lúc huấn luyện và chọn ngưỡng TAU, không sửa ----------
def fmt_thoi_han(th):
    th = th or {}
    if th.get('so') is None:
        return th.get('goc') or 'không rõ'
    return f"{th['so']} {th.get('don_vi', '')}".strip()

def fmt_le_phi(ds):
    if not ds:
        return 'không có thông tin'
    out = []
    for lp in ds:
        if lp.get('mien_phi'):
            s = 'miễn phí'
        elif lp.get('so_tien') is None:
            s = 'không rõ'
        else:
            s = f"{lp['so_tien']} {lp.get('tien_te') or ''}".strip()
        if lp.get('ghi_chu'):
            s += f" ({lp['ghi_chu']})"
        out.append(s)
    return '; '.join(out)

def build_sections(p):
    cq = p.get('co_quan') or {}
    secs = [
        ('Tên thủ tục', p.get('ten', '')),
        ('Lĩnh vực', ', '.join(l['ten'] for l in p.get('linh_vuc') or [])),
        ('Cơ quan thực hiện', cq.get('thuc_hien', '')),
        ('Đối tượng', p.get('doi_tuong', '')),
        ('Trình tự thực hiện', '\n'.join(p.get('trinh_tu') or [])),
        ('Thành phần hồ sơ', '\n'.join(
            f"- [{h.get('nhom','')}] {h.get('ten','')}"
            + (f" ({h['truong_hop']})" if h.get('truong_hop') else '')
            for h in p.get('ho_so') or [])),
        ('Cách thức, thời hạn, lệ phí', '\n'.join(
            f"- {c.get('hinh_thuc','')}: thời hạn {fmt_thoi_han(c.get('thoi_han'))}; "
            f"lệ phí {fmt_le_phi(c.get('le_phi'))}"
            for c in p.get('cach_thuc') or [])),
        ('Kết quả', '; '.join(k['ten'] for k in p.get('ket_qua') or [])),
        ('Yêu cầu, điều kiện', p.get('yeu_cau_dieu_kien', '')),
        ('Căn cứ pháp lý', '\n'.join(
            f"- {c.get('ma','')}: {c.get('ten','')}" for c in p.get('can_cu') or [])),
    ]
    return [(k, v.strip()) for k, v in secs if v and v.strip()]

def split_long(text, max_chars=MAX_CHARS):
    parts, cur = [], ''
    for line in text.split('\n'):
        while len(line) > max_chars:
            if cur:
                parts.append(cur); cur = ''
            parts.append(line[:max_chars]); line = line[max_chars:]
        if cur and len(cur) + len(line) + 1 > max_chars:
            parts.append(cur); cur = line
        else:
            cur = f'{cur}\n{line}' if cur else line
    if cur:
        parts.append(cur)
    return parts

def chunks_field_title(p):
    general, out = [], []
    for name, val in build_sections(p):
        if name in GENERAL:
            general.append(f'{name}: {val}')
        else:
            for part in split_long(val):
                out.append(f"Thủ tục: {p['ten']}\n{name}: {part}")
    return split_long('\n'.join(general)) + out


# ---------- Kiểm tra cấu trúc dữ liệu admin nhập ----------
def validate_procedure(p):
    if not isinstance(p, dict):
        return ['Dữ liệu phải là một đối tượng JSON']
    errs = []
    for k in ('ma_thu_tuc', 'ten'):
        if not isinstance(p.get(k), str) or not p[k].strip():
            errs.append(f'thiếu hoặc rỗng: {k}')
    for k in ('linh_vuc', 'ho_so', 'cach_thuc', 'ket_qua', 'can_cu', 'trinh_tu'):
        if p.get(k) is not None and not isinstance(p[k], list):
            errs.append(f'{k} phải là danh sách')
    if p.get('co_quan') is not None and not isinstance(p['co_quan'], dict):
        errs.append('co_quan phải là đối tượng')
    if errs:
        return errs
    try:
        if not chunks_field_title(p):
            errs.append('không tạo được nội dung để tìm kiếm')
    except Exception as e:
        errs.append(f'sai cấu trúc ({type(e).__name__}: {e}); đối chiếu với mẫu trong clean.json')
    return errs


# ---------- Bộ truy xuất ----------
def _h(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def _rrf(rank_lists, k=RRF_K):
    score = defaultdict(float)
    for lst in rank_lists:
        for rank, c in enumerate(lst, 1):
            score[c] += 1.0 / (k + rank)
    return [c for c, _ in sorted(score.items(), key=lambda x: -x[1])]

def _default_embed():
    from sentence_transformers import SentenceTransformer
    m = SentenceTransformer(EMB_NAME, device='cpu'); m.max_seq_length = 1024
    def f(texts, batch_size=8):
        v = m.encode(list(texts), batch_size=batch_size, normalize_embeddings=True,
                     show_progress_bar=False, convert_to_numpy=True)
        return np.asarray(v, dtype='float32')
    return f

def _default_rerank():
    from sentence_transformers import CrossEncoder
    m = CrossEncoder(RERANK_NAME, device='cpu', max_length=1024)
    return lambda q, texts: np.asarray(m.predict([(q, t) for t in texts], batch_size=8, show_progress_bar=False))

def _default_tok():
    from underthesea import word_tokenize
    def tok(text):
        return [w for w in word_tokenize(text, format='text').lower().split() if re.search(r'\w', w)]
    return tok


class _State:
    pass

class Retriever:
    def __init__(self, data_path, cache_dir, rerank_n=30, embed_fn=None, rerank_fn=None, tok_fn=None, log=print, runtime_path=None):
        self.data_path, self.cache_dir, self.rerank_n, self.log = data_path, cache_dir, rerank_n, log
        os.makedirs(cache_dir, exist_ok=True)
        self.backup_dir = os.path.join(os.path.dirname(os.path.abspath(data_path)), 'backups')
        self.embed = embed_fn or _default_embed()
        self.rerank = rerank_fn or _default_rerank()
        self.tok = tok_fn or _default_tok()
        self._wlock = threading.Lock()
        self._vec, self._tokc = {}, {}
        self.runtime_path = runtime_path or str(data_path) + '.rag-state.json'
        self.versions = {}
        self._load_caches()
        if os.path.isfile(self.runtime_path):
            with open(self.runtime_path, encoding='utf-8') as f:
                saved = json.load(f)
            self.versions = saved['versions']
            self.state = self._build({p['ma_thu_tuc']: p for p in saved['procedures']})
        else:
            self.state = self._build(self._read_procs())

    # --- dữ liệu ---
    def _read_procs(self):
        with open(self.data_path, encoding='utf-8') as f:
            data = json.load(f)
        procs = {}
        for p in data:
            procs[p['ma_thu_tuc']] = p
        return procs

    def _write_procs(self, procs):
        if os.path.exists(self.data_path):
            os.makedirs(self.backup_dir, exist_ok=True)
            shutil.copy2(self.data_path, os.path.join(self.backup_dir, time.strftime('clean-%Y%m%d-%H%M%S-') + str(time.time_ns() % 1000000) + '.json'))
            old = sorted(os.listdir(self.backup_dir))
            for fn in old[:-20]:
                os.remove(os.path.join(self.backup_dir, fn))
        tmp = self.data_path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            json.dump(list(procs.values()), f, ensure_ascii=False, indent=1)
        os.replace(tmp, self.data_path)          # ghi nguyên tử: không bao giờ để file dở dang

    # --- cache vector và token theo TỪNG ĐOẠN ---
    def _vec_path(self): return os.path.join(self.cache_dir, 'chunk_vectors.npz')
    def _tok_path(self): return os.path.join(self.cache_dir, 'chunk_tokens.json')

    def _load_caches(self):
        if os.path.exists(self._vec_path()):
            z = np.load(self._vec_path(), allow_pickle=False)
            self._vec = {h: v for h, v in zip(z['hashes'].tolist(), z['emb'])}
        if os.path.exists(self._tok_path()):
            self._tokc = json.load(open(self._tok_path(), encoding='utf-8'))

    def _save_caches(self, used):
        hs = [h for h in used if h in self._vec]
        if hs:
            tmp = self._vec_path() + '.tmp.npz'
            np.savez(tmp, hashes=np.array(hs), emb=np.stack([self._vec[h] for h in hs]))
            os.replace(tmp, self._vec_path())
        tmp = self._tok_path() + '.tmp'
        json.dump({h: self._tokc[h] for h in used if h in self._tokc}, open(tmp, 'w', encoding='utf-8'), ensure_ascii=False)
        os.replace(tmp, self._tok_path())

    def _seed_from_old_npy(self, texts, hashes):
        # Dùng lại file vector cũ (emb_field_title_<khóa>.npy từ Colab) nếu đúng khóa, để khỏi tính lại trên CPU
        key = hashlib.md5('\n'.join([EMB_NAME] + texts).encode('utf-8')).hexdigest()[:12]
        for fn in os.listdir(self.cache_dir):
            if fn.startswith('emb_field_title_') and fn.endswith('.npy') and key in fn:
                arr = np.load(os.path.join(self.cache_dir, fn))
                if arr.shape[0] == len(texts):
                    for h, v in zip(hashes, arr):
                        self._vec.setdefault(h, np.asarray(v, dtype='float32'))
                    self.log(f'Dùng lại vector cũ: {fn}')
                    return

    # --- dựng trạng thái tìm kiếm ---
    def _build(self, procs):
        import faiss
        from rank_bm25 import BM25Okapi
        texts, pids = [], []
        for ma, p in procs.items():
            for t in chunks_field_title(p):
                texts.append(t); pids.append(ma)
            for title, value in supplemental_sections(p):
                for part in split_long(value):
                    texts.append(f"Thủ tục: {p['ten']}\n{title}: {part}"); pids.append(ma)
        hashes = [_h(t) for t in texts]
        if not self._vec and texts:
            self._seed_from_old_npy(texts, hashes)
        miss = [i for i, h in enumerate(hashes) if h not in self._vec]
        if miss:
            self.log(f'Tính vector cho {len(miss)} đoạn mới...')
            for s in range(0, len(miss), 16):
                part = miss[s:s + 16]
                for i, v in zip(part, self.embed([texts[i] for i in part])):
                    self._vec[hashes[i]] = v
        for h, t in zip(hashes, texts):
            if h not in self._tokc:
                self._tokc[h] = self.tok(t)
        st = _State()
        st.by_id, st.texts, st.pids = dict(procs), texts, pids
        if texts:
            st.emb = np.stack([self._vec[h] for h in hashes]).astype('float32')
            st.faiss = faiss.IndexFlatIP(st.emb.shape[1]); st.faiss.add(st.emb)
            st.bm25 = BM25Okapi([self._tokc[h] for h in hashes])
        self._save_caches(hashes)
        return st

    # --- truy vấn ---
    def search(self, query, state=None):
        # Trả về (danh sách mã thủ tục xếp hạng, điểm reranker tốt nhất mỗi thủ tục, by_id cùng phiên bản dữ liệu)
        st = state if state is not None else self.state
        if not st.texts:
            return [], {}, st.by_id
        m = min(M_CHUNKS, len(st.texts))
        _, ids = st.faiss.search(self.embed([query]), m)
        vec = [int(i) for i in ids[0] if i >= 0]
        bm = [int(i) for i in np.argsort(-st.bm25.get_scores(self.tok(query)))[:m]]
        cand = _rrf([vec, bm])[:self.rerank_n]
        scores = np.asarray(self.rerank(query, [st.texts[c] for c in cand]))
        pids, best = [], {}
        for i in np.argsort(-scores):
            p = st.pids[cand[i]]
            if p not in best:
                best[p] = float(scores[i]); pids.append(p)
        pids = tthc_variants.prefer_general(query, pids, best, st.by_id)     # ưu tiên thủ tục chung khi câu hỏi không nêu trường hợp đặc biệt
        return pids, best, st.by_id

    def scoped_state(self, allowed):
        """Use only the exact database versions authorized for this request."""
        st = self.state
        if allowed is None:
            return st
        wanted = {(a.procedure_id, a.code, a.version) for a in allowed}
        by_id = {code: p for code, p in st.by_id.items()
                 if (p.get('_sync', {}).get('procedure_id'), code,
                     p.get('_sync', {}).get('version')) in wanted}
        if len(by_id) == len(st.by_id):
            return st
        import faiss
        from rank_bm25 import BM25Okapi
        view = _State()
        indexes = [i for i, code in enumerate(st.pids) if code in by_id]
        view.by_id = by_id
        view.texts = [st.texts[i] for i in indexes]
        view.pids = [st.pids[i] for i in indexes]
        if indexes:
            view.emb = st.emb[indexes]
            view.faiss = faiss.IndexFlatIP(view.emb.shape[1])
            view.faiss.add(view.emb)
            view.bm25 = BM25Okapi([self._tokc[_h(text)] for text in view.texts])
        return view

    def apply_sync(self, procedure_id, payload):
        """Commit versions, tombstones and procedures in one durable snapshot."""
        key = str(procedure_id)
        digest = hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False,
                                           separators=(',', ':')).encode('utf-8')).hexdigest()
        with self._wlock:
            current = self.versions.get(key)
            if current and payload['version'] <= current['version']:
                if payload['version'] == current['version'] and digest != current['digest']:
                    raise ValueError('Cùng phiên bản nhưng nội dung đồng bộ khác nhau.')
                return self._sync_result(procedure_id, current, False)
            procs = dict(self.state.by_id)
            for code, proc in list(procs.items()):
                if proc.get('_sync', {}).get('procedure_id') == procedure_id:
                    del procs[code]
            code = payload['code']
            occupied = procs.get(code)
            if occupied and occupied.get('_sync', {}).get('procedure_id') not in (None, procedure_id):
                if payload['active']:
                    raise ValueError('Mã thủ tục đang thuộc một bản ghi khác. Hãy thử đồng bộ lại.')
            else:
                procs.pop(code, None)
            if payload['active']:
                proc = deepcopy(payload['procedure'])
                errors = validate_procedure(proc)
                if errors:
                    raise ValueError('; '.join(errors))
                proc['_sync'] = {'procedure_id': procedure_id, 'version': payload['version']}
                procs[code] = proc
            versions = dict(self.versions)
            record = {'version': payload['version'], 'code': code, 'active': payload['active'], 'digest': digest}
            versions[key] = record
            new_state = self._build(procs)
            folder = os.path.dirname(os.path.abspath(self.runtime_path))
            os.makedirs(folder, exist_ok=True)
            tmp = self.runtime_path + '.tmp'
            try:
                with open(tmp, 'w', encoding='utf-8') as f:
                    json.dump({'schema_version': 1, 'versions': versions, 'procedures': list(procs.values())},
                              f, ensure_ascii=False)
                    f.flush()
                    os.fsync(f.fileno())
                os.replace(tmp, self.runtime_path)
                directory = os.open(folder, os.O_RDONLY | os.O_DIRECTORY)
                try:
                    os.fsync(directory)
                finally:
                    os.close(directory)
            finally:
                if os.path.exists(tmp):
                    os.remove(tmp)
            self.versions, self.state = versions, new_state
            return self._sync_result(procedure_id, record, True)

    def _sync_result(self, procedure_id, record, applied):
        return {'procedure_id': procedure_id, 'version': record['version'], 'code': record['code'],
                'active': record['active'], 'chunk_count': self.state.pids.count(record['code']) if record['active'] else 0,
                'applied': applied}

    # --- cập nhật tức thì ---
    def upsert(self, proc):
        errs = validate_procedure(proc)
        if errs:
            raise ValueError('; '.join(errs))
        with self._wlock:
            procs = dict(self.state.by_id)
            existed = proc['ma_thu_tuc'] in procs
            procs[proc['ma_thu_tuc']] = proc            # thay tại chỗ nếu đã có, thêm cuối nếu mới
            new_state = self._build(procs)              # lỗi ở đây thì dữ liệu cũ vẫn nguyên
            self._write_procs(procs)
            self.state = new_state                      # đổi con trỏ một lần
        return 'updated' if existed else 'created'

    def delete(self, ma):
        with self._wlock:
            if ma not in self.state.by_id:
                raise KeyError(ma)
            procs = {k: v for k, v in self.state.by_id.items() if k != ma}
            new_state = self._build(procs)
            self._write_procs(procs)
            self.state = new_state

    def reload(self):
        # Dùng khi sửa tay file clean.json
        with self._wlock:
            self.state = self._build(self._read_procs())
        return len(self.state.by_id)
