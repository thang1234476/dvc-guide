export const levels = { trung_uong: 'Trung ương', tinh: 'Tỉnh', huyen: 'Huyện', xa: 'Xã' };
export const statuses = { nhap: 'Bản nháp', dang_dung: 'Đang áp dụng', ngung: 'Ngừng áp dụng' };
export const asList = value => Array.isArray(value) ? value : [];
export const clone = value => JSON.parse(JSON.stringify(value));
export const agencyLabels = { thuc_hien: 'Cơ quan thực hiện', tham_quyen: 'Cơ quan có thẩm quyền', dia_chi_tiep_nhan: 'Địa chỉ tiếp nhận hồ sơ', uy_quyen: 'Cơ quan được ủy quyền', phoi_hop: 'Cơ quan phối hợp' };
export const sections = [['general', 'Thông tin chung'], ['agencies', 'Cơ quan'], ['submissions', 'Quy trình & cách nộp'], ['documents', 'Hồ sơ & biểu mẫu'], ['legal', 'Căn cứ & điều kiện'], ['results', 'Kết quả & từ khóa']];

export function initialContent(detail) {
  if (detail?.cleanData) return clone(detail.cleanData);
  const p = detail?.procedure;
  return { schema_version: '1.0', ma_thu_tuc: p?.code ?? '', ten: p?.name ?? '', so_quyet_dinh: '', cap_thuc_hien: p?.level ?? '', loai_thu_tuc: '',
    linh_vuc: asList(p?.fields).map(f => ({ id: f.code, ten: f.name })), doi_tuong: detail?.audience ?? '',
    co_quan: { thuc_hien: detail?.originalAgency ?? '', tham_quyen: '', dia_chi_tiep_nhan: '', uy_quyen: '', phoi_hop: '' },
    trinh_tu: asList(detail?.steps).map(s => s.description ?? s.title ?? ''),
    cach_thuc: asList(detail?.submissions).map(s => ({ hinh_thuc: s.channel, hinh_thuc_goc: s.originalChannel, thoi_han: { so: s.duration, don_vi: s.durationUnit, goc: s.originalDuration },
      le_phi: asList(s.fees).map(f => ({ so_tien: f.amount, tien_te: f.currency, mien_phi: f.free, ghi_chu: f.notes })), mo_ta: '' })),
    ho_so: asList(detail?.documents).map(d => ({ nhom: d.group, truong_hop: d.originalCase, ten: d.name, so_ban_chinh: d.originals, so_ban_sao: d.copies,
      mau_don: asList(d.forms).map(f => ({ ten: f.name, file_id: f.code, url: f.docxUrl || f.pdfUrl || '', loi_tai: null })) })),
    can_cu: asList(detail?.legalBases).map(l => ({ ma: l.reference, ten: l.name })), yeu_cau_dieu_kien: detail?.conditions ?? '',
    ket_qua: asList(detail?.results).map(ten => ({ ten, ma: '' })), tu_khoa: [] };
}

export function startingValues(detail, data) {
  return { code: data.ma_thu_tuc ?? '', name: data.ten ?? '', level: data.cap_thuc_hien || detail?.procedure.level || '', status: detail?.procedure.status ?? 'nhap',
    version: detail?.procedure.version ?? null, fieldIds: asList(detail?.procedure.fields).map(f => f.id), originalAgency: data.co_quan?.thuc_hien ?? '',
    audience: data.doi_tuong ?? '', conditions: data.yeu_cau_dieu_kien ?? '', portalUrl: detail?.portalUrl ?? '', source: detail?.source ?? '' };
}

export function toWriteRequest(values, data) {
  const content = clone(data);
  content.ma_thu_tuc = values.code.trim(); content.ten = values.name.trim(); content.cap_thuc_hien = values.level || '';
  content.doi_tuong = values.audience; content.yeu_cau_dieu_kien = values.conditions;
  content.co_quan = { ...content.co_quan, thuc_hien: values.originalAgency };
  return { ...values, code: content.ma_thu_tuc, name: content.ten, level: Object.hasOwn(levels, values.level) ? values.level : null,
    portalUrl: values.portalUrl.trim() || null, source: values.source.trim() || null, content };
}

export function updateItem(items, index, value) { return items.map((item, i) => i === index ? value : item); }
export function moveItem(items, index, direction) {
  const target = index + direction;
  if (target < 0 || target >= items.length) return items;
  const next = [...items]; [next[index], next[target]] = [next[target], next[index]]; return next;
}

export async function downloadJson(request, path, fallback = 'thu-tuc.json') {
  const { blob, filename } = await request(path, { download: true });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a'); link.href = url; link.download = filename || fallback;
  document.body.append(link); link.click(); link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
