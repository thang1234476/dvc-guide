"""tthc_dialog.py - lớp hội thoại: (1) hỏi lại khi có thủ tục 'cùng tên, khác cơ quan/cấp', (2) ghim thủ tục cho câu nối tiếp.
Chỉ phụ thuộc: tthc_forms.fold và tthc_variants.is_followup (file bạn đã có). KHÔNG gọi model, KHÔNG cần GPU.
Nhãn lựa chọn lấy từ dữ liệu (cơ quan thực hiện, đối tượng), không do model viết."""
import re
from collections import defaultdict
from app.services.forms import fold
from app.services.variants import is_followup

def _base(name):
    """Tên bỏ phần '(thực hiện tại ...)' và chuẩn hóa chính tả huỷ/hủy; dùng để gom các thủ tục 'anh em'."""
    n = re.sub(r'\(thực hiện tại[^)]*\)', '', (name or '').lower())
    return re.sub(r'\s+', ' ', n.replace('huỷ', 'hủy')).strip()

def build_groups(by_id):
    """{pid: [các pid cùng tên gốc, kể cả chính nó]} chỉ cho thủ tục có anh em (>=2)."""
    g = defaultdict(list)
    for pid, p in by_id.items():
        g[_base(p['ten'])].append(pid)
    out = {}
    for members in g.values():
        if len(members) > 1:
            for pid in members:
                out[pid] = sorted(members)
    return out

def _label_tokens(pid, by_id):
    p = by_id[pid]
    return set(fold((p.get('co_quan') or {}).get('thuc_hien', '') + ' ' + p.get('ten', '').split('(')[-1]).split())

def option_label(pid, by_id, group):
    """Nhãn ngắn cho người dùng: cơ quan thực hiện; nếu trùng trong nhóm thì thêm đối tượng; luôn lấy từ dữ liệu."""
    p = by_id[pid]
    cq = (p.get('co_quan') or {}).get('thuc_hien', '').strip() or 'Chưa rõ cơ quan'
    same = [q for q in group if q != pid and (by_id[q].get('co_quan') or {}).get('thuc_hien', '').strip() == cq]
    if same and p.get('doi_tuong'):
        return f"{cq} (đối tượng: {p['doi_tuong'].strip()})"
    return cq

def resolve_siblings(question, pid, by_id, groups):
    """Trả về ('answer', pid) hoặc ('choose', [pid...]).
    - pid không có anh em → trả lời luôn.
    - Câu hỏi nhắc rõ đúng MỘT thành viên (từ chỉ có ở cơ quan/cấp của thành viên đó) → chọn thành viên đó.
    - Còn lại → mời chọn."""
    group = groups.get(pid)
    if not group:
        return ('answer', pid)
    qtok = set(fold(question).split())
    toks = {m: _label_tokens(m, by_id) for m in group}
    common = set.intersection(*toks.values())
    hit = [m for m in group if (toks[m] - common) & qtok]
    if len(hit) == 1:
        return ('answer', hit[0])
    return ('choose', group)

class Session:
    """Trạng thái của MỘT cuộc trò chuyện; app Flutter giữ và gửi lại (hoặc server giữ theo conversation_id)."""
    def __init__(self, pinned=None):
        self.pinned = pinned          # procedure_id đang được hỏi
        self.turns = []               # [(câu hỏi, pid trả lời)] giữ vài lượt gần nhất để ghi log, KHÔNG đưa vào prompt

def plan_turn(question, session, by_id, groups, retrieve, forced_pid=None):
    """retrieve(question) -> danh sách pid xếp hạng. Trả về dict:
       {'action': 'answer'|'choose', 'pid': ..., 'options': [{'procedure_id','label'}], 'why': ...}"""
    if forced_pid:                                              # người dùng bấm một lựa chọn / "Hỏi về thủ tục này"
        session.pinned = forced_pid
        return {'action': 'answer', 'pid': forced_pid, 'why': 'forced'}
    if session.pinned and is_followup(question):                # "còn lệ phí thì sao?" → dùng thủ tục đã ghim
        return {'action': 'answer', 'pid': session.pinned, 'why': 'pinned_followup'}
    pids = retrieve(question)
    if not pids:
        return {'action': 'answer', 'pid': None, 'why': 'no_retrieval'}
    act, x = resolve_siblings(question, pids[0], by_id, groups)
    if act == 'choose':
        grp = x
        return {'action': 'choose', 'pid': None, 'why': 'siblings',
                'options': [{'procedure_id': m, 'label': option_label(m, by_id, grp)} for m in grp]}
    session.pinned = x
    return {'action': 'answer', 'pid': x, 'why': 'retrieval_top1'}
