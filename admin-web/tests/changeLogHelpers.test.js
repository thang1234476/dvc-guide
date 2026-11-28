import { test } from 'node:test';
import assert from 'node:assert/strict';
import { collectChanges, describePath, displayValue, localDateTime } from '../src/changeLogHelpers.js';

test('compares nested procedure snapshots without depending on object key order', () => {
  assert.deepEqual(collectChanges({ a: 1, b: { c: [] } }, { b: { c: [] }, a: 1 }), []);
  const diff = collectChanges({ procedure: { name: 'Tên cũ', version: 1 } }, { procedure: { name: 'Tên mới', version: 2 } });
  assert.deepEqual(diff.map(change => change.path), [['procedure', 'name'], ['procedure', 'version']]);
  assert.equal(describePath(diff[0].path), 'Thông tin thủ tục → Tên');
});

test('compares import JSON arrays and preserves additions, removals, null, false, zero and empty text', () => {
  const before = { ho_so: [{ ten: 'Tờ khai cũ', so_ban_chinh: null }, { ten: 'Giấy cũ' }], phi: 0, same: false, gone: 'X' };
  const after = { ho_so: [{ ten: 'Tờ khai mới', so_ban_chinh: 0 }], phi: null, same: false, added: '' };
  const diff = collectChanges(before, after);
  assert.equal(diff.length, 6);
  assert.equal(describePath(diff[0].path), 'Hồ sơ → Mục 1 → Tên');
  assert.deepEqual(diff.find(change => change.path.join('.') === 'ho_so.1.ten'), { path: ['ho_so', 1, 'ten'], before: 'Giấy cũ', after: undefined });
  assert.equal(displayValue(diff.find(change => change.path[0] === 'phi').after), 'Chưa có giá trị (null)');
  assert.equal(displayValue(undefined), '— (không có trường)');
  assert.equal(displayValue(false), 'Không (false)');
  assert.equal(displayValue(0), '0');
  assert.equal(displayValue(''), 'Chuỗi rỗng');
  assert.equal(displayValue('constructor'), 'constructor');
  assert.deepEqual(collectChanges({}, JSON.parse('{"constructor":"source value","__proto__":"metadata"}')),
    [{ path: ['constructor'], before: undefined, after: 'source value' }, { path: ['__proto__'], before: undefined, after: 'metadata' }]);
  assert.equal(describePath(['constructor']), 'constructor');
});

test('handles whole snapshots, empty containers and type changes', () => {
  assert.deepEqual(collectChanges(undefined, {}), [{ path: [], before: undefined, after: {} }]);
  assert.deepEqual(collectChanges([], []), []);
  assert.deepEqual(collectChanges(undefined, undefined), []);
  assert.deepEqual(collectChanges({ field: [] }, { field: {} }), [{ path: ['field'], before: [], after: {} }]);
  assert.deepEqual(collectChanges(undefined, { name: 'Mới' }), [{ path: ['name'], before: undefined, after: 'Mới' }]);
  assert.deepEqual(collectChanges({ name: 'Cũ' }, undefined), [{ path: ['name'], before: 'Cũ', after: undefined }]);
});

test('date inputs preserve the local instant and malformed query dates do not crash rendering', () => {
  const instant = '2026-11-28T03:04:05Z';
  assert.equal(new Date(localDateTime(instant)).toISOString(), new Date(instant).toISOString());
  assert.equal(localDateTime(null), '');
  assert.equal(localDateTime('not-a-date'), '');
});
