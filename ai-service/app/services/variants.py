# tthc_variants.py - Xử lý thủ tục "chung" và các biến thể của nó (có yếu tố nước ngoài, biên giới, lưu động...)
# Quy tắc: nếu tên thủ tục B = tên thủ tục A + thêm từ đặc biệt, mà câu hỏi không nhắc tới các từ thêm đó, thì ưu tiên A.
import re
from functools import lru_cache
from app.services.forms import fold

MARGIN = 0.05      # chỉ nâng thủ tục chung lên khi điểm không thấp hơn biến thể quá mức này
_SKIP = {'thu', 'tuc'}

@lru_cache(maxsize=8192)
def _tok(s):
    return frozenset(fold(s).split())

@lru_cache(maxsize=8192)
def _name_tok(s):
    return _tok(s) - _SKIP

def variant_extra(general_name, specific_name):
    # Trả về tập từ thêm nếu specific_name = general_name + từ khác, ngược lại None
    a, b = _name_tok(general_name), _name_tok(specific_name)
    if len(a) >= 2 and a < b:
        return b - a
    return None

def _mentioned(extra, qtok):
    return len(extra & qtok) / len(extra)

def prefer_general(question, pids, best, by_id, margin=None, top_n=5):
    # Câu hỏi không nhắc từ đặc biệt -> đưa thủ tục chung lên trước biến thể.
    # Câu hỏi nhắc từ đặc biệt (vd "biên giới") -> đưa biến thể đó lên trước thủ tục chung.
    margin = MARGIN if margin is None else margin
    qtok = _tok(question)
    order = list(pids[:top_n])
    pairs = []
    for g in order:
        for sp in order:
            if g != sp:
                extra = variant_extra(by_id[g]['ten'], by_id[sp]['ten'])
                if extra:
                    pairs.append((g, sp, _mentioned(extra, qtok)))
    for g, sp, m in pairs:
        if m < 0.4 and order.index(g) > order.index(sp) and best.get(g, 0.0) >= best.get(sp, 0.0) - margin:
            order.remove(g); order.insert(order.index(sp), g)
        elif m >= 0.4 and order.index(sp) > order.index(g) and best.get(sp, 0.0) >= best.get(g, 0.0) - margin:
            order.remove(sp); order.insert(order.index(g), sp)
    return order + list(pids[top_n:])

def variant_note(question, used, pids, by_id, top_n=5):
    # Nếu thủ tục dùng để trả lời là biến thể mà câu hỏi không nhắc tới, nhắc người dùng phạm vi áp dụng
    qtok = _tok(question)
    for g in pids[:top_n]:
        if g == used:
            continue
        extra = variant_extra(by_id[g]['ten'], by_id[used]['ten'])
        if extra and _mentioned(extra, qtok) < 0.4:
            return (f"Lưu ý: thủ tục trên áp dụng cho trường hợp «{by_id[used]['ten']}». "
                    "Nếu trường hợp của bạn khác, bạn cho mình biết thêm để mình tra đúng thủ tục.")
    return ''

def last_user(history):
    # history: danh sách {role, content} hoặc [người dùng, trợ lý]; trả về câu hỏi gần nhất của người dùng
    for m in reversed(history or []):
        if isinstance(m, dict) and m.get('role') == 'user' and str(m.get('content', '')).strip():
            return str(m['content']).strip()[:300]
        if isinstance(m, (list, tuple)) and m and str(m[0] or '').strip():
            return str(m[0]).strip()[:300]
    return ''


# Câu hỏi nối tiếp: chỉ gồm từ hỏi và từ chỉ thuộc tính (giấy tờ, lệ phí, thời hạn, mẫu...), không có chủ đề riêng
_QW = set('cho toi la gi nhung nao the muon biet xin giup hoi co khong duoc nua vay a va thi de lam nhu cua can ma con sao'.split())
_ATTR = set('giay to ho phi le thoi han bao lau nhieu mau bieu tuc buoc quy trinh chuan bi nop o dau ai mat tien khai'.split())

def is_followup(question):
    return len(set(fold(question).split()) - _QW - _ATTR) == 0


# ---- Chính sách khi câu hỏi chung chung: trả lời trường hợp thông thường, nói rõ giả định, mời chọn trường hợp khác ----
def variants_of(general_pid, question, by_id, limit=6):
    # Các thủ tục là biến thể của general_pid (tên = tên chung + từ thêm) mà câu hỏi không nhắc tới
    gname, qtok, out = by_id[general_pid]['ten'], _tok(question), []
    for pid, p in by_id.items():
        if pid == general_pid:
            continue
        extra = variant_extra(gname, p['ten'])
        if extra and _mentioned(extra, qtok) < 0.4:
            out.append(pid)
    out.sort(key=lambda p: (len(by_id[p]['ten']), by_id[p]['ten']))
    return out[:limit]

def assumption_text(general_name):
    return (f"Câu hỏi của bạn chưa nói rõ trường hợp, nên mình trả lời theo trường hợp thông thường "
            f"(không kèm điều kiện đặc biệt): «{general_name}».")

def options_text(options, by_id, numbered=False):
    head = "Nếu trường hợp của bạn khác, bạn chọn một trường hợp dưới đây" + (" (gõ số tương ứng)" if numbered else "") + " để mình trả lời đúng hơn:"
    lines = [(f"{i}. " if numbered else "- ") + by_id[p]['ten'] for i, p in enumerate(options, 1)]
    return head + "\n" + "\n".join(lines)
