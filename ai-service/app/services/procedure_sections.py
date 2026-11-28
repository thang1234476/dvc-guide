"""Additional business fields, keeping the trained base chunk renderer unchanged."""


def supplemental_sections(procedure):
    agency = procedure.get('co_quan') or {}
    sections = []
    for title, value in [
        ('Số quyết định', procedure.get('so_quyet_dinh')),
        ('Cấp thực hiện theo nguồn', procedure.get('cap_thuc_hien')),
        ('Loại thủ tục theo nguồn', procedure.get('loai_thu_tuc')),
        ('Cơ quan có thẩm quyền', agency.get('tham_quyen')),
        ('Địa chỉ tiếp nhận hồ sơ', agency.get('dia_chi_tiep_nhan')),
        ('Cơ quan được ủy quyền', agency.get('uy_quyen')),
        ('Cơ quan phối hợp', agency.get('phoi_hop')),
        ('Từ khóa', '; '.join(procedure.get('tu_khoa') or [])),
    ]:
        if isinstance(value, str) and value.strip():
            sections.append((title, value))

    documents = []
    for document in procedure.get('ho_so') or []:
        quantities = []
        for key, label in [('so_ban_chinh', 'bản chính'), ('so_ban_sao', 'bản sao')]:
            if document.get(key) is not None:
                quantities.append(f"{document[key]} {label}")
        forms = [f"{form.get('ten') or 'Biểu mẫu'}: {form.get('url') or 'chưa có link tải'}"
                 for form in document.get('mau_don') or []]
        if quantities or forms:
            documents.append(f"- {document.get('ten', '')} [{document.get('nhom') or ''}; {document.get('truong_hop') or ''}]: "
                             + '; '.join(quantities + forms))
    if documents:
        sections.append(('Số lượng giấy tờ và biểu mẫu', '\n'.join(documents)))

    submissions = []
    for submission in procedure.get('cach_thuc') or []:
        details = []
        original_duration = (submission.get('thoi_han') or {}).get('goc')
        if original_duration:
            details.append(f'Thời gian giải quyết nguyên văn: {original_duration}')
        if submission.get('mo_ta'):
            details.append(f"Mô tả cách thức: {submission['mo_ta']}")
        if details:
            submissions.append(f"- {submission.get('hinh_thuc', '')}: " + '; '.join(details))
    if submissions:
        sections.append(('Mô tả cách thức và thời hạn nguồn', '\n'.join(submissions)))
    results = [f"{result.get('ten', '')} (Mã: {result['ma']})" for result in procedure.get('ket_qua') or [] if result.get('ma')]
    if results:
        sections.append(('Mã kết quả xử lý', '\n'.join(results)))
    return sections
