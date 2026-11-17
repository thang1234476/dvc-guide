import React, { useState } from 'react';

export const levels = { trung_uong: 'Trung ương', tinh: 'Tỉnh', huyen: 'Huyện', xa: 'Xã' };
export const statuses = { nhap: 'Bản nháp', dang_dung: 'Đang áp dụng', ngung: 'Ngừng áp dụng' };

function startingValues(detail) {
  const summary = detail?.procedure;
  return {
    code: summary?.code ?? '',
    name: summary?.name ?? '',
    level: summary?.level ?? '',
    status: summary?.status ?? 'nhap',
    version: summary?.version ?? null,
    fieldIds: summary?.fields.map(({ id }) => id) ?? [],
    originalAgency: detail?.originalAgency ?? '',
    audience: detail?.audience ?? '',
    conditions: detail?.conditions ?? '',
    portalUrl: detail?.portalUrl ?? '',
    source: detail?.source ?? '',
  };
}

export function ProcedureEditor({ detail, fields, save, retire, close }) {
  const [values, setValues] = useState(() => startingValues(detail));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [confirmRetire, setConfirmRetire] = useState(false);

  const change = (name, value) => setValues((current) => ({ ...current, [name]: value }));
  const move = (index) => {
    const ids = [...values.fieldIds];
    [ids[index - 1], ids[index]] = [ids[index], ids[index - 1]];
    change('fieldIds', ids);
  };

  async function apply(operation) {
    setError('');
    setBusy(true);
    try {
      await operation();
    } catch (failure) {
      setError(failure.message);
      setBusy(false);
    }
  }

  function submit(event) {
    event.preventDefault();
    if (confirmRetire) return;
    const input = { ...values, code: values.code.trim(), name: values.name.trim(), level: values.level || null };
    for (const key of ['originalAgency', 'audience', 'conditions', 'portalUrl', 'source']) {
      input[key] = values[key].trim() || null;
    }
    void apply(() => save(input));
  }

  return (
    <section className="panel editor" aria-labelledby="form-title">
      <div className="section-heading">
        <h2 id="form-title">{detail ? 'Chỉnh sửa thủ tục' : 'Thêm thủ tục'}</h2>
        {detail && <span className="muted">Phiên bản {detail.procedure.version}</span>}
      </div>
      <form onSubmit={submit}>
        <fieldset disabled={busy}>
          <label className="full">Tên thủ tục
            <input required maxLength={1000} value={values.name} onChange={(e) => change('name', e.target.value)} />
          </label>
          <label>Mã thủ tục
            <input required maxLength={50} value={values.code} onChange={(e) => change('code', e.target.value)} />
          </label>
          <label>Cấp thực hiện
            <select value={values.level} onChange={(e) => change('level', e.target.value)}>
              <option value="">Chưa xác định</option>
              {Object.entries(levels).map(([key, label]) => <option key={key} value={key}>{label}</option>)}
            </select>
          </label>
          <label>Trạng thái
            <select value={values.status} onChange={(e) => change('status', e.target.value)}>
              {Object.entries(statuses).map(([key, label]) => <option key={key} value={key}>{label}</option>)}
            </select>
          </label>
          <label>Thêm lĩnh vực
            <select value="" disabled={values.fieldIds.length >= 50} onChange={(e) => {
              if (e.target.value) change('fieldIds', [...values.fieldIds, Number(e.target.value)]);
            }}>
              <option value="">{fields.length ? 'Chọn lĩnh vực' : 'Chưa có lĩnh vực'}</option>
              {fields.filter(({ id }) => !values.fieldIds.includes(id))
                .map(({ id, name }) => <option key={id} value={id}>{name}</option>)}
            </select>
          </label>
          {values.fieldIds.length > 0 && <ol className="field-list full" aria-label="Lĩnh vực theo thứ tự">
            {values.fieldIds.map((id, index) => {
              const name = fields.find((field) => field.id === id)?.name || String(id);
              return <li key={id}>
                <span>{name}{index === 0 && <small>Lĩnh vực chính</small>}</span>
                {index > 0 && <button type="button" onClick={() => move(index)} aria-label={`Đưa ${name} lên`}>↑</button>}
                <button type="button" onClick={() => change('fieldIds', values.fieldIds.filter((value) => value !== id))}
                  aria-label={`Bỏ ${name}`}>Bỏ</button>
              </li>;
            })}
          </ol>}
          <label>Đường dẫn cổng dịch vụ
            <input type="url" maxLength={1000} value={values.portalUrl} onChange={(e) => change('portalUrl', e.target.value)} />
          </label>
          <label>Nguồn dữ liệu
            <input maxLength={500} value={values.source} onChange={(e) => change('source', e.target.value)} />
          </label>
          <div className="full form-field">
            <label htmlFor="procedure-agency">Cơ quan thực hiện theo nguồn</label>
            <textarea id="procedure-agency" maxLength={16000} value={values.originalAgency}
              onChange={(e) => change('originalAgency', e.target.value)} />
          </div>
          <div className="full form-field">
            <label htmlFor="procedure-audience">Đối tượng áp dụng</label>
            <textarea id="procedure-audience" maxLength={16000} value={values.audience}
              onChange={(e) => change('audience', e.target.value)} />
          </div>
          <div className="full form-field">
            <label htmlFor="procedure-conditions">Điều kiện</label>
            <textarea id="procedure-conditions" maxLength={16000} value={values.conditions}
              onChange={(e) => change('conditions', e.target.value)} />
          </div>
        </fieldset>
        {error && <p className="error" role="alert">{error}</p>}
        {confirmRetire && <p role="status">Sau khi ngừng áp dụng, thủ tục sẽ ẩn khỏi tra cứu công khai.</p>}
        <div className="form-actions">
          {confirmRetire ? <>
            <button type="button" className="danger" disabled={busy} onClick={() => apply(retire)}>Xác nhận ngừng áp dụng</button>
            <button type="button" disabled={busy} onClick={() => setConfirmRetire(false)}>Quay lại</button>
          </> : <>
            <button type="submit" className="primary" disabled={busy}>{busy ? 'Đang lưu…' : 'Lưu thủ tục'}</button>
            <button type="button" disabled={busy} onClick={close}>Hủy</button>
            {detail && detail.procedure.status !== 'ngung' &&
              <button type="button" className="danger" disabled={busy} onClick={() => setConfirmRetire(true)}>Ngừng áp dụng</button>}
          </>}
        </div>
      </form>
    </section>
  );
}
