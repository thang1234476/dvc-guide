import re

# ---------- Kiểm tra câu trả lời sau khi sinh ----------
NORM = lambda s: re.sub(r'\s+', ' ', re.sub(r'[^\w\s]', ' ', s.lower())).strip()
_NUM = re.compile(r'\d[\d\.,]*')
# Chặn khẳng định "quy định/thủ tục còn hiệu lực, hiện hành". KHÔNG chặn "giấy khám sức khỏe còn hiệu lực" (nói về giấy tờ) và
# "phát hiện hành vi" (chữ "hiện hành" nằm trong "phát hiện hành vi").
_VALID = re.compile(
    r'(?<!phát )(?<!thể )\bhiện hành\b(?! vi)|đang áp dụng|mới nhất|'
    r'(quy định|văn bản|luật|nghị định|thông tư|nghị quyết|quyết định|thủ tục|căn cứ)[^.\n]{0,40}(còn|đang|vẫn|có)\s+hiệu lực', re.I)

_TIME_PAIR = re.compile(r'(\d[\d\.,]*)\s*(ngày|tháng|năm|giờ|tuổi|phút)\b', re.I)
def _time_pairs(s):
    return {(re.sub(r'\D', '', m.group(1)).lstrip('0') or '0', m.group(2).lower()) for m in _TIME_PAIR.finditer(s)}

def verify_answer(ans, ctx_text, ctx_names, strict_numbers=True, need_source=True):
    # Trả về (đạt, lý do). Không đạt thì server trả câu từ chối.
    if _VALID.search(ans):
        return False, 'khẳng định hiệu lực'
    if strict_numbers:
        nums = lambda s: {re.sub(r'\D', '', m).lstrip('0') for m in _NUM.findall(s)}      # bỏ số 0 đầu: "05" == "5"
        bad = sorted(n for n in nums(ans) - nums(ctx_text) if len(n) >= 2)
        if bad:
            return False, f'số không có trong ngữ cảnh: {bad}'
    if strict_numbers:                      # số MỘT chữ số + đơn vị thời gian ("7 ngày"): guard cũ bỏ qua vì chỉ xét số >= 2 chữ số
        bad = sorted(_time_pairs(ans) - _time_pairs(ctx_text))
        if bad:
            return False, f'thời hạn/độ tuổi không có trong ngữ cảnh: {bad}'
    if need_source:
        m = re.search(r'Nguồn:\s*(.+)', ans)
        if not m:
            return False, 'thiếu dòng Nguồn'
        s = NORM(m.group(1))
        if not s or not any(NORM(n) in s or s in NORM(n) for n in ctx_names):
            return False, 'Nguồn không khớp thủ tục trong ngữ cảnh'
    return True, ''


