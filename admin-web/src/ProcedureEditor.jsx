import { useState } from 'react';
import { FormSection, Icon } from './ui.jsx';
import { ContentField, ContentList, DocumentFields, SubmissionFields } from './ProcedureContentFields.jsx';
import { agencyLabels, asList, initialContent, levels, sections, startingValues, statuses, toWriteRequest } from './procedureContent.js';
export { levels, statuses } from './procedureContent.js';

export function ProcedureEditor({ detail, fields, save, retire, close, exportJson, readOnly = false, onEdit }) {
  const [data, setData] = useState(() => initialContent(detail));
  const [keywords, setKeywords] = useState(() => asList(initialContent(detail).tu_khoa).join('\n'));
  const [values, setValues] = useState(() => startingValues(detail, initialContent(detail)));
  const [busy, setBusy] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState('');
  const [confirmRetire, setConfirmRetire] = useState(false);
  const knownFields = [...new Map([...(detail?.procedure.fields ?? []), ...fields].map(field => [field.id, field])).values()];
  const remainingFields = knownFields.filter(({ id }) => !values.fieldIds.includes(id));
  const change = (key, value) => setValues(current => ({ ...current, [key]: value }));
  const content = (key, value) => setData(current => ({ ...current, [key]: value }));
  const setAgency = (key, value) => {
    setData(current => ({ ...current, co_quan: { ...current.co_quan, [key]: value } }));
    if (key === 'thuc_hien') change('originalAgency', value);
  };
  async function apply(operation) {
    setError(''); setBusy(true);
    try { await operation(); }
    catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }
  async function exportSaved() {
    setError(''); setExporting(true);
    try { await exportJson(); } catch (failure) { setError(failure.message); }
    finally { setExporting(false); }
  }

  return <section className="panel editor" aria-labelledby="form-title">
    <div className="section-heading">
      <div><h2 id="form-title">{readOnly ? 'Chi tiết thủ tục' : detail ? 'Chỉnh sửa thủ tục' : 'Thêm thủ tục'}</h2>
        {detail && <small>Mã: {detail.procedure.code} · Phiên bản {detail.procedure.version}</small>}</div>
      {detail && <button type="button" disabled={busy || exporting} onClick={exportSaved}><Icon name="download" />{exporting ? 'Đang xuất…' : 'Xuất JSON bản đã lưu'}</button>}
    </div>
    <nav className="editor-section-nav" aria-label="Các phần của thủ tục">{sections.map(([id, title]) => <a key={id} href={`#procedure-${id}`}>{title}</a>)}</nav>
    <form onSubmit={event => { event.preventDefault(); if (!confirmRetire && !readOnly) void apply(() => save(toWriteRequest(values, keywords === asList(data.tu_khoa).join('\n') ? data : { ...data, tu_khoa: keywords.split('\n').map(word => word.trim()).filter(Boolean) }))); }} onInvalidCapture={event => {
      let parent = event.target.parentElement;
      while (parent) { if (parent.tagName === 'DETAILS') parent.open = true; parent = parent.parentElement; }
    }}>
      <fieldset disabled={busy || readOnly}>
        <FormSection number="01" id="procedure-general" title="Thông tin chung" description="Giữ nguyên mã và giá trị theo nguồn; có thể bổ sung thông tin còn thiếu.">
          <div className="form-grid procedure-general-grid">
            <ContentField label="Tên thủ tục" className="full" required maxLength={1000} value={values.name} onChange={v => change('name', v)} />
            <ContentField label="Mã thủ tục" required maxLength={50} value={values.code} onChange={v => change('code', v)} />
            <ContentField label="Số quyết định" value={data.so_quyet_dinh} onChange={v => content('so_quyet_dinh', v)} />
            <label>Cấp thực hiện<select value={values.level} onChange={e => change('level', e.target.value)}>
              <option value="">Chưa xác định</option>{values.level && !Object.hasOwn(levels, values.level) && <option value={values.level}>{values.level} (theo nguồn)</option>}
              {Object.entries(levels).map(([key, label]) => <option key={key} value={key}>{label}</option>)}
            </select></label>
            <ContentField label="Loại thủ tục" value={data.loai_thu_tuc} onChange={v => content('loai_thu_tuc', v)} placeholder="Ví dụ: OTHER" />
            <label>Trạng thái<select value={values.status} onChange={e => change('status', e.target.value)}>{Object.entries(statuses).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></label>
            <ContentField label="Đối tượng thực hiện" multiline className="full" value={values.audience} onChange={v => change('audience', v)} />
          </div>
          <div className="procedure-fields" role="group" aria-labelledby="procedure-fields-title">
            <h4 id="procedure-fields-title">Lĩnh vực của thủ tục</h4>
            <p className="muted" id="procedure-fields-help">{values.fieldIds.length ? `Đã chọn ${values.fieldIds.length} lĩnh vực. Lĩnh vực đầu tiên là lĩnh vực chính.` : 'Chưa chọn lĩnh vực cho thủ tục.'}</p>
            {values.fieldIds.length > 0 && <ol className="field-list" aria-label="Lĩnh vực đã chọn">{values.fieldIds.map((id, index) => {
              const name = knownFields.find(field => field.id === id)?.name || `Lĩnh vực #${id}`;
              return <li key={id}><span>{name}{index === 0 && <small>Lĩnh vực chính</small>}</span>
                {index > 0 && <button type="button" onClick={() => { const ids = [...values.fieldIds]; [ids[index - 1], ids[index]] = [ids[index], ids[index - 1]]; change('fieldIds', ids); }} aria-label={`Đưa ${name} lên`}>↑</button>}
                <button type="button" onClick={() => change('fieldIds', values.fieldIds.filter(value => value !== id))} aria-label={`Bỏ ${name}`}>Bỏ</button></li>;
            })}</ol>}
            <label htmlFor="procedure-add-field">{values.fieldIds.length ? 'Thêm lĩnh vực khác' : 'Thêm lĩnh vực'}</label>
            <select id="procedure-add-field" value="" disabled={!remainingFields.length || values.fieldIds.length >= 50} aria-describedby="procedure-fields-help" onChange={e => { if (e.target.value) change('fieldIds', [...values.fieldIds, Number(e.target.value)]); }}>
              <option value="">{values.fieldIds.length >= 50 ? 'Đã chọn tối đa 50 lĩnh vực' : !knownFields.length ? 'Chưa có lĩnh vực trong danh mục' : remainingFields.length ? 'Chọn lĩnh vực để thêm…' : 'Đã chọn tất cả lĩnh vực'}</option>
              {remainingFields.map(({ id, name }) => <option key={id} value={id}>{name}</option>)}
            </select>
          </div>
        </FormSection>
        <FormSection number="02" id="procedure-agencies" title="Cơ quan và nơi tiếp nhận">
          <div className="form-grid">{Object.entries(agencyLabels).map(([key, label]) => <ContentField key={key} label={label} multiline value={key === 'thuc_hien' ? values.originalAgency : data.co_quan?.[key]} onChange={v => setAgency(key, v)} />)}</div>
        </FormSection>
        <FormSection number="03" id="procedure-submissions" title="Quy trình và cách nộp">
          <ContentList title="Trình tự thực hiện" noun="bước thực hiện" value={data.trinh_tu} onChange={v => content('trinh_tu', v)} create={() => ''} getTitle={text => text} render={(text, update) => <ContentField label="Nội dung bước thực hiện" multiline required value={text} onChange={update} />} />
          <SubmissionFields value={data.cach_thuc} onChange={v => content('cach_thuc', v)} />
        </FormSection>
        <FormSection number="04" id="procedure-documents" title="Hồ sơ và biểu mẫu">
          <DocumentFields value={data.ho_so} onChange={v => content('ho_so', v)} />
        </FormSection>
        <FormSection number="05" id="procedure-legal" title="Căn cứ pháp lý và điều kiện">
          <ContentList title="Căn cứ pháp lý" noun="căn cứ pháp lý" value={data.can_cu} onChange={v => content('can_cu', v)} create={() => ({ ma: '', ten: '' })} getTitle={law => law.ma ? `${law.ma} — ${law.ten}` : law.ten}
            render={(law, update) => <div className="form-grid"><ContentField label="Số hiệu văn bản" value={law.ma} onChange={v => update({ ...law, ma: v })} maxLength={100} /><ContentField label="Tên / nội dung căn cứ pháp lý" multiline required className="full" value={law.ten} onChange={v => update({ ...law, ten: v })} maxLength={1000} /></div>} />
          <ContentField label="Yêu cầu, điều kiện" multiline value={values.conditions} onChange={v => change('conditions', v)} />
        </FormSection>
        <FormSection number="06" id="procedure-results" title="Kết quả và từ khóa">
          <ContentList title="Kết quả xử lý" noun="kết quả" value={data.ket_qua} onChange={v => content('ket_qua', v)} create={() => ({ ten: '', ma: '' })} getTitle={result => result.ten}
            render={(result, update) => <div className="form-grid"><ContentField label="Mã kết quả" value={result.ma} onChange={v => update({ ...result, ma: v })} /><ContentField label="Tên kết quả" required value={result.ten} onChange={v => update({ ...result, ten: v })} maxLength={1000} /></div>} />
          <ContentField label="Từ khóa — mỗi dòng một từ khóa" multiline value={keywords} onChange={setKeywords} />
          <div className="form-grid source-controls"><ContentField label="Đường dẫn cổng dịch vụ" type="url" maxLength={1000} value={values.portalUrl} onChange={v => change('portalUrl', v)} /><ContentField label="Nguồn dữ liệu" maxLength={500} value={values.source} onChange={v => change('source', v)} /></div>
          {data.id && <p className="muted source-identity">ID nguồn: {data.id} · Cấu trúc: {data.schema_version ?? '1.0'}</p>}
        </FormSection>
      </fieldset>
      {error && <p className="error" role="alert">{error}</p>}
      {confirmRetire && <p role="status">Sau khi ngừng áp dụng, thủ tục sẽ ẩn khỏi tra cứu công khai và được gỡ khỏi RAG.</p>}
      <div className="form-actions editor-actions">{readOnly ? <><button key="edit" type="button" className="primary" onClick={event => { event.preventDefault(); onEdit(); }}><Icon name="edit" />Chỉnh sửa</button><button type="button" onClick={close}>Đóng</button></> : confirmRetire ? <>
        <button type="button" className="danger" disabled={busy} onClick={() => apply(retire)}>Xác nhận ngừng áp dụng</button><button type="button" disabled={busy} onClick={() => setConfirmRetire(false)}>Quay lại</button>
      </> : <><button type="submit" className="primary" disabled={busy}><Icon name="check" />{busy ? 'Đang lưu…' : 'Lưu thủ tục'}</button><button type="button" disabled={busy} onClick={close}>Hủy</button>
        {detail && detail.procedure.status !== 'ngung' && <button type="button" className="danger" disabled={busy} onClick={() => setConfirmRetire(true)}>Ngừng áp dụng</button>}</>}
      </div>
      {detail && <small>File JSON được xuất từ phiên bản đã lưu. Lưu thay đổi trước khi xuất để lấy nội dung mới nhất.</small>}
    </form>
  </section>;
}
