import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initialContent, startingValues, toWriteRequest, updateItem, moveItem } from '../src/procedureContent.js';

const raw = { schema_version: '1.0', id: 'original-id', ma_thu_tuc: '3.000323', ten: 'Đăng ký giám sát việc giám hộ', cap_thuc_hien: '', loai_thu_tuc: 'OTHER', so_quyet_dinh: '', doi_tuong: '', co_quan: { thuc_hien: '', tham_quyen: 'UBND', extra: null }, ho_so: [{ ten: 'Lưu ý', nhom: 'nop', truong_hop: 'Lưu ý:', so_ban_chinh: 0, so_ban_sao: null, mau_don: [{ ten: 'Tờ khai', file_id: 'drive-id', url: 'https://drive.google.com/example' }] }], cach_thuc: [{ hinh_thuc: 'truc_tiep', thoi_han: { so: 3, don_vi: 'khac', goc: '3 OTHER' }, le_phi: [{ mien_phi: false, so_tien: 0, tien_te: null }], mo_ta: '' }], yeu_cau_dieu_kien: '', tu_khoa: ['giám hộ'], nguon: { ngay_cao: 'original-date' }, extra_metadata: { untouched: true } };
const detail = { procedure: { code: raw.ma_thu_tuc, name: raw.ten, level: null, status: 'dang_dung', version: 3, fields: [{ id: 8, code: 'src-code', name: 'Hộ tịch' }] }, cleanData: raw };

test('opening full content makes an independent copy and preserves the original clean schema', () => {
  const content = initialContent(detail);
  content.ho_so[0].mau_don[0].url = 'https://example.test/new';
  assert.equal(raw.ho_so[0].mau_don[0].url, 'https://drive.google.com/example');
  assert.equal(content.ho_so[0].truong_hop, 'Lưu ý:');
  assert.deepEqual(content.extra_metadata, raw.extra_metadata);
});

test('saving preserves unknown fields, nulls, zero, source IDs and separate state controls', () => {
  const content = initialContent(detail), values = startingValues(detail, content);
  const request = toWriteRequest(values, content);
  assert.deepEqual(request.content, raw);
  assert.deepEqual(request.fieldIds, [8]);
  assert.equal(request.status, 'dang_dung');
  assert.equal(request.level, null);
  assert.equal(request.content.cach_thuc[0].thoi_han.goc, '3 OTHER');
  assert.equal(request.content.ho_so[0].so_ban_chinh, 0);
  assert.equal(request.content.ho_so[0].so_ban_sao, null);
});

test('editing common values changes their JSON counterparts without changing source metadata', () => {
  const content = initialContent(detail), values = startingValues(detail, content);
  values.name = ' Tên mới '; values.originalAgency = 'Cơ quan mới'; values.conditions = 'Điều kiện mới'; values.level = 'tinh';
  const request = toWriteRequest(values, content);
  assert.equal(request.content.ten, 'Tên mới');
  assert.equal(request.content.co_quan.thuc_hien, 'Cơ quan mới');
  assert.equal(request.content.co_quan.tham_quyen, 'UBND');
  assert.equal(request.content.cap_thuc_hien, 'tinh');
  assert.deepEqual(request.content.nguon, raw.nguon);
  values.level = 'UNKNOWN_SOURCE_LEVEL';
  const unknown = toWriteRequest(values, content);
  assert.equal(unknown.level, null);
  assert.equal(unknown.content.cap_thuc_hien, 'UNKNOWN_SOURCE_LEVEL');
});

test('reordering or editing nested items does not mutate another item or discard form links', () => {
  const forms = raw.ho_so[0].mau_don;
  const list = [raw.ho_so[0], { ten: 'Giấy tờ khác', mau_don: [] }];
  const next = moveItem(list, 1, -1);
  assert.equal(next[1], list[0]);
  assert.equal(list[0].ten, 'Lưu ý');
  assert.deepEqual(next[1].mau_don, forms);
  const edited = updateItem(next, 0, { ...next[0], ten: 'Đã sửa' });
  assert.equal(edited[0].ten, 'Đã sửa'); assert.equal(next[0].ten, 'Giấy tờ khác');
});
