export const actionLabels = { tao: 'Tạo mới', sua: 'Chỉnh sửa', xoa: 'Xóa / ngừng áp dụng' };

const fieldLabels = {
  procedure: 'Thông tin thủ tục', code: 'Mã', name: 'Tên', level: 'Cấp thực hiện', status: 'Trạng thái',
  version: 'Phiên bản', fields: 'Lĩnh vực', originalAgency: 'Cơ quan thực hiện gốc', audience: 'Đối tượng',
  updatedAt: 'Thời điểm cập nhật', createdAt: 'Thời điểm tạo', saved: 'Đã lưu yêu thích',
  conditions: 'Điều kiện', portalUrl: 'Link dịch vụ công', source: 'Nguồn dữ liệu', cases: 'Trường hợp',
  documents: 'Giấy tờ', steps: 'Trình tự', submissions: 'Cách nộp', agencies: 'Cơ quan', results: 'Kết quả',
  legalBases: 'Căn cứ pháp lý', group: 'Nhóm', originals: 'Số bản chính', copies: 'Số bản sao',
  required: 'Bắt buộc', notes: 'Ghi chú', form: 'Biểu mẫu chính', forms: 'Biểu mẫu',
  originalCase: 'Trường hợp gốc', caseId: 'ID trường hợp', channel: 'Hình thức', order: 'Thứ tự',
  title: 'Tiêu đề', description: 'Mô tả', duration: 'Thời hạn', durationUnit: 'Đơn vị thời hạn',
  originalDuration: 'Thời hạn gốc', originalChannel: 'Hình thức gốc', fees: 'Lệ phí',
  free: 'Miễn phí', amount: 'Số tiền', currency: 'Tiền tệ', address: 'Địa chỉ', reference: 'Số hiệu',
  docxUrl: 'File Word', pdfUrl: 'File PDF', exampleUrl: 'File mẫu', instructions: 'Hướng dẫn điền',
  effectiveDate: 'Ngày có hiệu lực', issuedDate: 'Ngày ban hành', expiryDate: 'Ngày hết hiệu lực',
  issuer: 'Cơ quan ban hành', type: 'Loại', validity: 'Hiệu lực', article: 'Điều khoản',
  id: 'ID', ma_thu_tuc: 'Mã thủ tục', ten: 'Tên', linh_vuc: 'Lĩnh vực', cap_thuc_hien: 'Cấp thực hiện',
  loai_thu_tuc: 'Loại thủ tục', doi_tuong: 'Đối tượng', co_quan: 'Cơ quan', thuc_hien: 'Thực hiện',
  tham_quyen: 'Thẩm quyền', dia_chi_tiep_nhan: 'Địa chỉ tiếp nhận', uy_quyen: 'Ủy quyền', phoi_hop: 'Phối hợp',
  trinh_tu: 'Trình tự', cach_thuc: 'Cách nộp', ho_so: 'Hồ sơ', can_cu: 'Căn cứ pháp lý',
  yeu_cau_dieu_kien: 'Yêu cầu, điều kiện', ket_qua: 'Kết quả', tu_khoa: 'Từ khóa', nguon: 'Nguồn',
  chat_luong: 'Chất lượng dữ liệu', nhom: 'Nhóm', truong_hop: 'Trường hợp', so_ban_chinh: 'Số bản chính',
  so_ban_sao: 'Số bản sao', mau_don: 'Biểu mẫu', file_id: 'ID file nguồn', loi_tai: 'Lỗi tải',
  hinh_thuc: 'Hình thức', hinh_thuc_goc: 'Hình thức gốc', thoi_han: 'Thời hạn', le_phi: 'Lệ phí',
  so: 'Số', don_vi: 'Đơn vị', goc: 'Giá trị gốc', so_tien: 'Số tiền', tien_te: 'Tiền tệ',
  mien_phi: 'Miễn phí', ghi_chu: 'Ghi chú', mo_ta: 'Mô tả', ma: 'Mã', so_quyet_dinh: 'Số quyết định',
  schema_version: 'Phiên bản cấu trúc', phan_loai_goc: 'Phân loại gốc', dan_xuat: 'Dữ liệu dẫn xuất',
};

export function describePath(path) {
  return path.length ? path.map(key => typeof key === 'number' ? `Mục ${key + 1}` : Object.hasOwn(fieldLabels, key) ? fieldLabels[key] : key).join(' → ') : 'Toàn bộ dữ liệu';
}

// Compare object keys independently of their order. Arrays are compared by position.
// Undefined means an absent field; null remains a distinct stored value.
export function collectChanges(before, after, path = []) {
  if (Object.is(before, after)) return [];
  const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
  if ((object(before) || before === undefined) && (object(after) || after === undefined)) {
    const keys = [...new Set([...Object.keys(before ?? {}), ...Object.keys(after ?? {})])];
    const ownValue = (value, key) => value && Object.hasOwn(value, key) ? value[key] : undefined;
    if (keys.length) return keys.flatMap(key => collectChanges(ownValue(before, key), ownValue(after, key), [...path, key]));
  } else if ((Array.isArray(before) || before === undefined) && (Array.isArray(after) || after === undefined)) {
    const length = Math.max(before?.length ?? 0, after?.length ?? 0);
    if (length) return Array.from({ length }, (_, index) => collectChanges(before?.[index], after?.[index], [...path, index])).flat();
  }
  // Equal empty containers do not represent a change.
  if (Array.isArray(before) && Array.isArray(after) && !before.length && !after.length) return [];
  if (object(before) && object(after) && !Object.keys(before).length && !Object.keys(after).length) return [];
  return [{ path, before, after }];
}

export function displayValue(value) {
  if (value === undefined) return '— (không có trường)';
  if (value === null) return 'Chưa có giá trị (null)';
  if (value === '') return 'Chuỗi rỗng';
  if (typeof value === 'boolean') return value ? 'Có (true)' : 'Không (false)';
  if (typeof value === 'object') return JSON.stringify(value, null, 2);
  const statuses = { dang_dung: 'Đang áp dụng', nhap: 'Bản nháp', ngung: 'Ngừng áp dụng' };
  return Object.hasOwn(statuses, value) ? `${statuses[value]} (${value})` : String(value);
}

export function localDateTime(instant) {
  const date = new Date(instant);
  if (!instant || Number.isNaN(date.getTime())) return '';
  const pad = number => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}
