import re
from app.services.retrieval import build_sections
from app.core.rules import SYSTEM_PROMPT as GEN_SYSTEM

CAPS_TOP = {'Trình tự thực hiện': 4000, 'Thành phần hồ sơ': 3500, 'Yêu cầu, điều kiện': 1000}
CAPS_OTHER = {'Trình tự thực hiện': 1500, 'Thành phần hồ sơ': 1500, 'Yêu cầu, điều kiện': 600}
SKIP_SEC = {'Căn cứ pháp lý'}
TRUNC_MARK = '(… còn tiếp, đã rút gọn)'

def smart_cut(text, cap):
    if len(text) <= cap:
        return text, False
    head = text[:cap]
    cut = max(head.rfind('\n'), head.rfind('. '), head.rfind('; '))
    if cut < cap * 0.5:
        cut = cap - 1
    return head[:cut + 1].rstrip(), True

_FORM = {'truc_tiep': 'Nộp trực tiếp', 'truc_tuyen': 'Nộp trực tuyến', 'buu_chinh': 'Nộp qua bưu chính'}

def humanize(val):
    for k, v in _FORM.items():
        val = re.sub(rf'^- {k}:', f'- {v}:', val, flags=re.M)
    val = re.sub(r'(\d[\d\.,]*) ngay_lam_viec', r'\1 ngày làm việc', val)
    val = re.sub(r'(\d[\d\.,]*) ngay\b', r'\1 ngày', val)
    val = re.sub(r'(\d[\d\.,]*) gio\b', r'\1 giờ', val)
    val = re.sub(r'(\d[\d\.,]*) thang\b', r'\1 tháng', val)
    val = re.sub(r'(\d[\d\.,]*) khac\b', r'\1 (không rõ đơn vị thời gian)', val)
    return val

def compact_proc(p, rank=1):
    caps = CAPS_TOP if rank == 1 else CAPS_OTHER
    parts = []
    for name, val in build_sections(p):
        if name in SKIP_SEC:
            continue
        if name == 'Cách thức, thời hạn, lệ phí':
            val = humanize(val)
        if name in caps:
            val, cut = smart_cut(val, caps[name])
            if cut:
                val += '\n' + TRUNC_MARK
        parts.append(f'{name}: {val}')
    return '\n'.join(parts)

def build_context(pids, by_id, k=3):
    return '\n\n'.join(
        f'[Thủ tục {i}]\n{compact_proc(by_id[pid], rank=i)}'
        for i, pid in enumerate(pids[:k], 1)
    )

def build_messages(question, pids, by_id, k=3):
    user = f'NGỮ CẢNH:\n{build_context(pids, by_id, k)}\n\nCÂU HỎI: {question}'
    return [
        {'role': 'system', 'content': GEN_SYSTEM},
        {'role': 'user', 'content': user},
    ]
