"""tthc_mau_hoi.py - B2: nhận diện câu XIN BIỂU MẪU và xác định thủ tục; không xác định được thì hỏi lại ĐÚNG MỘT câu, không đoán.
Không gọi model, không cần GPU. Phụ thuộc: tthc_mau_don.py, tthc_dialog.py (và các file nó import).
Đầu vào history: danh sách lượt, mỗi lượt {'role': 'user'|'assistant', 'content': str, 'sources': [{'procedure_id': ...}]}
(sources chỉ có ở lượt assistant). retrieve(question)->[pid xếp hạng] do nơi gọi truyền vào (pipeline truy xuất thật)."""
import re
from app.services.mau_don import fold, mau_cua_thu_tuc, tra_loi_mau, NO_FORM, HEAD, hop_le, ten_sach
from app.services.dialog import build_groups, option_label, resolve_siblings

# ---------- 1) Nhận diện câu xin mẫu ----------
_STRONGFORM = re.compile(r'\b(bieu mau|mau don|mau to khai|to khai|don de nghi|don xin|phieu de nghi|phieu|mau so|form)\b')
_FILEWORD = re.compile(r'\b(file|link|duong dan|tai ve|download|pdf|word|docx)\b')
_REQ = re.compile(r'\b(tai|download|link|duong dan|file|lay|xin|gui|dua|o dau|co san|in ra|pdf|word|docx|ban pdf|ban word|cho (toi|minh|em|anh|chi|to|tui)|can (mot|1)|cho xin)\b')
_ACTION = re.compile(r'\b(gui|tai|download|link|duong dan|file|pdf|word|docx|in ra)\b')   # có từ này thì "điền" không còn nghĩa hỏi cách điền
_CONTENT = re.compile(r'\b(gom|nhung gi|bao nhieu|cach dien|huong dan|noi dung|can gi|can nhung|thoi han|le phi|bao lau|la gi|khac gi|co can|phai co|nop|nhu the nao|chuan bi|giay to|liet ke|cac loai)\b')
_DIEN = re.compile(r'\bdien\b')
_MA = re.compile(r'\b([A-Za-z]{1,3})\s?-?\s?(\d{1,3}[A-Za-z]?)\b')

def la_xin_mau(question):
    """True nếu người dùng đang xin FILE/MẪU để tải. Cố ý chặt: 'tờ khai gồm gì', 'nộp tờ khai ở đâu', 'mẫu hộ chiếu màu gì' KHÔNG phải xin mẫu.
    Chữ 'mẫu' đứng một mình (không kèm tờ khai/đơn/biểu mẫu) chỉ tính là xin mẫu nếu có từ yêu cầu (tải, xin, gửi...), có mã mẫu (TK03),
    hoặc câu không có chủ đề nào khác ('mẫu đâu')."""
    raw = (question or '').lower()
    f = fold(question)
    strong = bool(_STRONGFORM.search(f))
    bare = bool(re.search(r'\bmẫu\b', raw))
    if not (strong or bare or _FILEWORD.search(f)):
        return False
    if _CONTENT.search(f) or (_DIEN.search(f) and not _ACTION.search(f)):
        return False
    if _REQ.search(f):
        return True
    if strong or _FILEWORD.search(f):
        return len(f.split()) <= 8
    return bool(_MA.search(question or '')) or not co_chu_de_rieng(question)

# ---------- 2) Câu hỏi có chủ đề riêng hay chỉ là "cho tôi mẫu" ----------
_SKIP = set(('cho toi minh em anh chi la gi nhung nao the muon biet xin giup hoi co khong duoc nua vay a va thi de lam nhu cua can ma con '
             'tai ve link duong dan file download lay gui dua form don mau bieu to khai phieu o dau co san in ra mot cai cac thu tuc nay do '
             'vui long oi nhe nha ha di ban voi dum cai nay kia giup minh nhan roi dau luon').split())
def co_chu_de_rieng(question):
    return len(set(fold(question).split()) - _SKIP) > 0

# Câu nối tiếp kiểu "còn mẫu cho người nước ngoài thì sao": không đủ để biết trường hợp nào -> hỏi lại
_NOITIEP = re.compile(r'^(vay |the |the la |vay thi )?con\b|\bthi sao\b')
def la_noi_tiep_mo_ho(question):
    return bool(_NOITIEP.search(fold(question)))

def tim_mau_theo_ma(question, by_id, toi_da=5):
    """Câu có mã mẫu (TK03, NA5, M01a...): tìm trong TÊN FILE của mau_don. Trả [{'ten','url'}] (gộp trùng url) hoặc []."""
    codes = {(a + b).lower() for a, b in _MA.findall(question or '')}
    if not codes:
        return []
    out, seen = [], set()
    for p in by_id.values():
        for h in p.get('ho_so') or []:
            for m in h.get('mau_don') or []:
                if not hop_le(m) or m['url'] in seen:
                    continue
                toks = fold(ten_sach(m.get('ten'))).replace(' ', '')
                if any(re.match(re.escape(c) + r'(?!\d)', toks) for c in codes):
                    seen.add(m['url']); out.append({'ten': ten_sach(m.get('ten')), 'url': m['url']})
    return out[:toi_da]

# ---------- 3) Xác định thủ tục ----------
def _pids_luot_gan_nhat(history):
    """Các pid trong lượt assistant GẦN NHẤT (giữ thứ tự, bỏ trùng). Lượt gần nhất không có nguồn (vd lời từ chối)
    -> trả [] để hỏi lại; KHÔNG lục lượt cũ hơn vì chủ đề có thể đã đổi."""
    for m in reversed(history or []):
        if isinstance(m, dict) and m.get('role') == 'assistant':
            out = []
            for s in m.get('sources') or []:
                pid = (s.get('procedure_id') or s.get('ma')) if isinstance(s, dict) else s
                if pid and pid not in out:
                    out.append(pid)
            return out
    return []

pids_luot_gan_nhat = _pids_luot_gan_nhat

def _lua_chon(pids, by_id, groups, theo_ten=False):
    """theo_ten=True: các thủ tục KHÁC nhau -> nhãn là tên thủ tục. Mặc định (nhóm anh em cùng tên) -> nhãn là cơ quan thực hiện."""
    if theo_ten:
        return [{'procedure_id': p, 'label': by_id[p]['ten'][:110]} for p in pids]
    return [{'procedure_id': p, 'label': option_label(p, by_id, groups.get(p) or [p])} for p in pids]

def _hoi_lai(cau_hoi, options=None, ly_do=''):
    return {'la_xin_mau': True, 'hanh_dong': 'hoi_lai', 'pid': None, 'cau_tra_loi': cau_hoi, 'options': options or [], 'forms': [], 'ly_do': ly_do}

def _tra_loi(pid, by_id, ly_do):
    return {'la_xin_mau': True, 'hanh_dong': 'tra_loi', 'pid': pid, 'cau_tra_loi': tra_loi_mau(pid, by_id), 'options': [],
            'forms': mau_cua_thu_tuc(pid, by_id)['mau'], 'ly_do': ly_do}

def _cung_mau(pids, by_id):
    """True nếu mọi thủ tục trong nhóm có cùng tập link (kể cả cùng rỗng) -> không cần hỏi chọn."""
    return len({frozenset(m['url'] for m in mau_cua_thu_tuc(p, by_id)['mau']) for p in pids}) == 1

def xu_ly_xin_mau(question, by_id, procedure_id=None, history=None, retrieve=None, groups=None):
    """Trả về dict: la_xin_mau (False nếu không phải xin mẫu -> để pipeline thường xử lý),
    hanh_dong ('tra_loi' | 'hoi_lai'), pid, cau_tra_loi, options, ly_do (để ghi log)."""
    if not la_xin_mau(question):
        return {'la_xin_mau': False, 'hanh_dong': None, 'pid': None, 'cau_tra_loi': '', 'options': [], 'forms': [], 'ly_do': ''}
    groups = groups if groups is not None else build_groups(by_id)

    # (a) app gửi procedure_id (đang xem/ghim thủ tục này) -> dùng luôn
    if procedure_id:
        if procedure_id in by_id:
            return _tra_loi(procedure_id, by_id, 'procedure_id do app gửi')
        return _hoi_lai('Mình chưa xác định được thủ tục bạn đang xem. Bạn muốn lấy biểu mẫu cho thủ tục nào?', ly_do='procedure_id không có trong dữ liệu')

    # (b0) có mã mẫu (TK03...) và khớp tên file -> trả đúng các file đó, không cần biết thủ tục
    theo_ma = tim_mau_theo_ma(question, by_id)
    if theo_ma:
        txt = '\n'.join([HEAD] + [f"- {m['ten']}: {m['url']}" for m in theo_ma])
        return {'la_xin_mau': True, 'hanh_dong': 'tra_loi', 'pid': None, 'cau_tra_loi': txt, 'options': [], 'forms': theo_ma, 'ly_do': 'khớp mã mẫu trong tên file'}

    # (b1) "còn mẫu cho người nước ngoài thì sao": nối tiếp mơ hồ -> hỏi lại, không đoán trường hợp
    if la_noi_tiep_mo_ho(question):
        cands = _pids_luot_gan_nhat(history)
        if cands:
            return _hoi_lai('Bạn muốn lấy biểu mẫu cho trường hợp nào? Bạn cho mình tên đầy đủ của thủ tục hoặc trường hợp nhé.',
                            _lua_chon(cands[:3], by_id, groups, theo_ten=True), 'nối tiếp mơ hồ, có history')
        return _hoi_lai('Bạn muốn lấy biểu mẫu cho thủ tục hoặc trường hợp nào? Bạn cho mình tên thủ tục nhé.', ly_do='nối tiếp mơ hồ, không có history')

    # (b) câu hỏi có chủ đề riêng ("mẫu tờ khai đăng ký kết hôn") -> truy xuất
    if co_chu_de_rieng(question):
        pids = retrieve(question) if retrieve else []
        if not pids:
            return _hoi_lai('Bạn muốn lấy biểu mẫu cho thủ tục nào? Bạn cho mình tên thủ tục nhé.', ly_do='không truy xuất được')
        top = pids[0]
        grp = groups.get(top)
        if grp and not _cung_mau(grp, by_id):
            return _hoi_lai('Thủ tục này có nhiều trường hợp, mỗi trường hợp có mẫu khác nhau. Bạn đang làm ở trường hợp nào?',
                            _lua_chon(grp, by_id, groups), 'anh em khác mẫu')
        return _tra_loi(top, by_id, 'truy xuất top-1')

    # (c) không có chủ đề riêng ("cho tôi tải mẫu") -> lấy từ lượt trả lời gần nhất có nguồn
    cands = _pids_luot_gan_nhat(history)
    if len(cands) == 1:
        pid = cands[0]
        grp = groups.get(pid)
        if grp and not _cung_mau(grp, by_id):
            return _hoi_lai('Thủ tục này có nhiều trường hợp, mỗi trường hợp có mẫu khác nhau. Bạn đang làm ở trường hợp nào?',
                            _lua_chon(grp, by_id, groups), 'anh em khác mẫu (từ history)')
        return _tra_loi(pid, by_id, 'từ lượt trả lời trước')
    if len(cands) > 1:
        return _hoi_lai('Câu trả lời trước nhắc tới nhiều thủ tục. Bạn muốn lấy biểu mẫu cho thủ tục nào?',
                        _lua_chon(cands[:3], by_id, groups, theo_ten=True), 'nhiều nguồn ở lượt trước')
    return _hoi_lai('Bạn muốn lấy biểu mẫu cho thủ tục nào? Bạn cho mình tên thủ tục nhé.', ly_do='không có thủ tục nào trong history')
