# tthc_forms.py - Biểu mẫu: nhận diện câu xin mẫu, xác định thủ tục, trả đường dẫn tải về.
# QUY TẮC ĐÃ CHỐT: nguồn biểu mẫu DUY NHẤT là ho_so[].mau_don trong clean.json (xem tthc_mau_don.py). Model không bao giờ tự sinh/sửa link.
# CÁCH DÙNG MỚI: xin_mau(...) ở cuối file. Các hàm theo bieu_mau.json (draft_registry, find_forms, form_reply, public_form,
# merge_registry...) là CŨ, giữ lại để không làm hỏng chỗ gọi cũ; KHÔNG dùng chúng làm nguồn link nữa.
import re, os, json, unicodedata, hashlib

def fold(s):
    # chữ thường, bỏ dấu, đ -> d, bỏ dấu câu: để "TỜ KHAI" khớp "to khai"
    s = unicodedata.normalize('NFD', (s or '').lower().replace('đ', 'd'))
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'\s+', ' ', re.sub(r'[^\w\s]', ' ', s)).strip()

def wants_form(question):
    # Nhận diện câu XIN MẪU (chặt hơn bản cũ: "tờ khai gồm gì", "nộp tờ khai ở đâu" không phải xin mẫu)
    from app.services.mau_hoi import la_xin_mau
    return la_xin_mau(question)

_STOP = set('cua cho toi va la mot cac nhung theo ve muon lay xin tai gi nao'.split())
_GENERIC = set('to khai mau bieu don phieu so de nghi xin ban hanh kem theo'.split())

def _info(s):
    return set(fold(s).split()) - _GENERIC - _STOP
_FORMLIKE = re.compile(r'\b(to khai|don de nghi|don xin|phieu|mau so|mau|bieu mau)\b')
_CODE = re.compile(r'mẫu\s*(?:số\s*)?([A-Za-z][A-Za-z/\-]*\d[A-Za-z0-9/\-\.]*|\d[A-Za-z0-9/\-\.]*)', re.I)

def _short_name(name):
    n = re.split(r'\s*\(|\s+ban hành|\s+theo mẫu', name, maxsplit=1)[0].strip(' ,;:-')
    return n or name

def _key(ma, ten):
    return ma if ma else 'F' + hashlib.md5(fold(ten).encode()).hexdigest()[:8]

def draft_registry(procedures):
    # Rút danh sách biểu mẫu từ phần thành phần hồ sơ của dữ liệu. Các cột url để trống cho người quản trị điền.
    reg = {}
    for p in procedures:
        for h in p.get('ho_so') or []:
            ten = (h.get('ten') or '').strip()
            if not ten or not _FORMLIKE.search(fold(ten)):
                continue
            m = _CODE.search(ten)
            ma = m.group(1).strip('.,;)') if m else ''
            key = _key(ma, ten)
            short = _short_name(ten)
            if len(_info(short)) < 2:                          # tên quá chung ("Tờ khai"): hiển thị nguyên văn để phân biệt
                short = ten[:120]
            e = reg.setdefault(key, {'key': key, 'ma': ma, 'ten': short, 'ten_goc': ten, 'aliases': [],
                                     'thu_tuc_ids': [], 'docx_url': '', 'pdf_url': '', 'copy_url': '', 'ghi_chu': ''})
            if p['ma_thu_tuc'] not in e['thu_tuc_ids']:
                e['thu_tuc_ids'].append(p['ma_thu_tuc'])
    return sorted(reg.values(), key=lambda e: (-len(e['thu_tuc_ids']), e['ten']))

def load_registry(path):
    if not os.path.exists(path):
        return []
    return json.load(open(path, encoding='utf-8'))

def save_registry(path, reg):
    tmp = path + '.tmp'
    json.dump(reg, open(tmp, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    os.replace(tmp, path)

def has_file(f):
    return bool(f.get('docx_url') or f.get('pdf_url') or f.get('copy_url'))

def find_forms(question, pids, registry):
    # Trả về (direct, in_proc): mẫu khớp với điều người dùng gõ, và mẫu thuộc các thủ tục vừa truy xuất
    fq = fold(question); qinfo = set(fq.split()) - _GENERIC - _STOP
    scored = []
    for f in registry:
        sc = 0.0
        for n in ([f['ma']] if f.get('ma') else []) + list(f.get('aliases') or []):
            fn = fold(n)
            if len(fn) >= 3 and re.search(r'\b' + re.escape(fn) + r'\b', fq):
                sc = 2.0                                        # nhắc thẳng mã hoặc bí danh
        finfo = _info(f.get('ten', ''))
        if sc == 0 and len(finfo) >= 2:                         # tên chỉ gồm từ chung chung thì không khớp theo tên
            inter = len(finfo & qinfo)
            if inter >= 2:
                rec, prec = inter / len(finfo), inter / max(1, len(qinfo))
                sc = 2 * rec * prec / (rec + prec)
                if re.search(r'\b' + re.escape(fold(f['ten'])) + r'\b', fq):
                    sc += 1.0                                   # nhắc nguyên tên
        if sc >= 0.45:
            scored.append((sc, f))
    scored.sort(key=lambda x: -x[0])
    exact = [f for sc, f in scored if sc >= 1.5]
    direct = exact if exact else [f for _, f in scored[:3]]
    in_proc = [f for f in registry if set(f.get('thu_tuc_ids') or []) & set(pids)][:8]
    return direct, in_proc

def public_form(f, base_url=''):
    def u(x):
        return (base_url.rstrip('/') + x) if x and x.startswith('/') and base_url else x
    return {'key': f.get('key'), 'ma': f.get('ma'), 'ten': f.get('ten'),
            'docx_url': u(f.get('docx_url')), 'pdf_url': u(f.get('pdf_url')), 'copy_url': u(f.get('copy_url'))}

def form_reply(forms, base_url=''):
    # Câu trả lời cố định, không qua model: không thể bịa đường dẫn
    lines = ['Bạn có thể tải biểu mẫu ở các đường dẫn dưới đây:' if any(has_file(f) for f in forms)
             else 'Hệ thống nhận ra biểu mẫu bạn cần nhưng hiện chưa có file để tải:']
    for f in forms:
        pf = public_form(f, base_url)
        head = '- ' + pf['ten'] + (f" (mẫu {pf['ma']})" if pf.get('ma') else '')
        links = []
        if pf['docx_url']: links.append('  Bản Word để soạn: ' + pf['docx_url'])
        if pf['pdf_url']:  links.append('  Bản PDF: ' + pf['pdf_url'])
        if pf['copy_url']: links.append('  Tạo bản sao để soạn trên Google Docs: ' + pf['copy_url'])
        lines.append(head if links else head + ': chưa có file tải trong hệ thống.')
        lines.extend(links)
    return '\n'.join(lines)


def merge_registry(existing, drafted):
    # Giữ nguyên đường dẫn đã nhập, chỉ cập nhật danh sách thủ tục dùng mẫu và thêm mẫu mới
    by = {e['key']: e for e in existing}
    for d in drafted:
        if d['key'] in by:
            by[d['key']]['thu_tuc_ids'] = d['thu_tuc_ids']
        else:
            by[d['key']] = d
    return list(by.values())

def validate_form(e):
    errs = []
    if not isinstance(e, dict) or not str(e.get('ten', '')).strip():
        return ['thiếu tên biểu mẫu (ten)']
    for k in ('docx_url', 'pdf_url', 'copy_url'):
        u = e.get(k) or ''
        if u and not (u.startswith('http://') or u.startswith('https://') or u.startswith('/files/')):
            errs.append(f'{k} phải bắt đầu bằng http://, https:// hoặc /files/')
    return errs


# =====================================================================
# B3 - CÁCH DÙNG MỚI (nguồn link: clean.json -> ho_so[].mau_don)
# =====================================================================
def xin_mau(question, by_id, procedure_id=None, history=None, retrieve=None, groups=None):
    """Xử lý câu xin biểu mẫu. Trả về dict:
       la_xin_mau (False -> để pipeline hỏi đáp thường xử lý), hanh_dong ('tra_loi'|'hoi_lai'), pid,
       cau_tra_loi (văn bản cố định ghép từ dữ liệu, KHÔNG qua model), options [{procedure_id,label}], ly_do (ghi log).
    history: [{'role','content','sources':[{'procedure_id'}]}]; retrieve(question)->[pid xếp hạng]."""
    from app.services.mau_hoi import xu_ly_xin_mau
    return xu_ly_xin_mau(question, by_id, procedure_id=procedure_id, history=history, retrieve=retrieve, groups=groups)

def mau_cua_thu_tuc(pid, by_id):
    """Danh sách mẫu có link của một thủ tục (dùng cho trang Chi tiết thủ tục): {'mau':[{'ten','url'}], 'cau_co_dinh':..., 'thieu_mot_phan':...}"""
    from app.services.mau_don import mau_cua_thu_tuc as _f
    return _f(pid, by_id)
