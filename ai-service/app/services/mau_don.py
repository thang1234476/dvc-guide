"""tthc_mau_don.py - B1: lấy biểu mẫu của một thủ tục từ clean.json (ho_so[].mau_don). KHÔNG cần GPU, KHÔNG gọi model.
Quy tắc: link chỉ lấy NGUYÊN VĂN từ dữ liệu; thủ tục không có mẫu hợp lệ -> câu cố định; tuyệt đối không nói "không có biểu mẫu"."""
import re, unicodedata

NO_FORM = "Trong dữ liệu hiện có chưa có file mẫu tải về cho thủ tục này."
HEAD = "Bạn có thể tải biểu mẫu ở các đường dẫn dưới đây:"
PARTIAL = "Một số giấy tờ khác trong hồ sơ chưa có file mẫu tải về trong dữ liệu hiện có."

def fold(s):
    s = unicodedata.normalize('NFD', (s or '').lower().replace('đ', 'd'))
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'\s+', ' ', re.sub(r'[^\w\s]', ' ', s)).strip()

def hop_le(m):
    """Mẫu dùng được: có url http(s) và không có lỗi tải."""
    u = m.get('url')
    return isinstance(u, str) and u.startswith(('http://', 'https://')) and not m.get('loi_tai')

def ten_sach(ten):
    """Tên file -> tên hiển thị: bỏ đuôi file và số thứ tự đầu tên ("10. "). Không đổi nội dung còn lại."""
    t = re.sub(r'\.(docx?|pdf|xlsx?|pptx?|rtf|odt)\s*$', '', (ten or '').strip(), flags=re.I)
    t = re.sub(r'^\s*\d{1,2}\s*[\.\)\-]\s*', '', t)
    return t.strip() or (ten or '').strip()

_FORMLIKE = re.compile(r'\b(to khai|don|phieu|mau|van ban de nghi|giay de nghi|bao cao|cong van)\b')
def giong_bieu_mau(ten_ho_so):
    return bool(_FORMLIKE.search(fold(ten_ho_so)))

def mau_cua_thu_tuc(pid, by_id):
    """Trả về dict:
       mau: [{'ten','url'}] (đã gộp trùng url, giữ thứ tự ho_so) | cau_co_dinh: NO_FORM hoặc None
       thieu_mot_phan: True nếu còn hồ sơ có tên giống biểu mẫu mà không có link"""
    p = by_id.get(pid)
    if p is None:
        raise KeyError(f'Không có thủ tục {pid}')
    mau, seen, thieu = [], set(), False
    for h in p.get('ho_so') or []:
        ok = [m for m in (h.get('mau_don') or []) if hop_le(m)]
        for m in ok:
            if m['url'] not in seen:
                seen.add(m['url']); mau.append({'ten': ten_sach(m.get('ten')), 'url': m['url']})
        if not ok and giong_bieu_mau(h.get('ten', '')):
            thieu = True
    return {'pid': pid, 'mau': mau, 'cau_co_dinh': None if mau else NO_FORM, 'thieu_mot_phan': bool(mau) and thieu}

def tra_loi_mau(pid, by_id):
    """Câu trả lời hoàn chỉnh, ghép từ dữ liệu, không qua model."""
    r = mau_cua_thu_tuc(pid, by_id)
    if not r['mau']:
        return NO_FORM
    lines = [HEAD] + [f"- {m['ten']}: {m['url']}" for m in r['mau']]
    if r['thieu_mot_phan']:
        lines.append(PARTIAL)
    return '\n'.join(lines)

_GEN = set('to khai mau don so phieu de nghi giay van ban doc docx pdf'.split())
def nghi_gan_nham(by_id):
    """Báo cáo để KIỂM TAY (không tự loại): mục mau_don mà tên file không có từ nội dung nào chung với tên hồ sơ."""
    out = []
    for pid, p in by_id.items():
        for h in p.get('ho_so') or []:
            ht = set(fold(h.get('ten', '')).split())
            for m in h.get('mau_don') or []:
                ft = {t for t in fold(ten_sach(m.get('ten'))).split() if not t.isdigit() and t not in _GEN and len(t) > 1}
                if ft and not (ft & ht):
                    out.append({'pid': pid, 'ho_so': h.get('ten', '')[:80], 'file': m.get('ten', '')[:80]})
    return out
