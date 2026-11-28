import { useRef, useState } from 'react';
import { Link } from 'react-router';
import { Icon, PageHeading, Pagination, PanelHeading, TableScroll } from './ui.jsx';

const actions = { CREATE: 'Thêm mới', UPDATE: 'Cập nhật', SKIP: 'Bỏ qua', INVALID: 'Có lỗi' };

export function ImportProceduresPage({ request }) {
  const [data, setData] = useState(null);
  const [fileName, setFileName] = useState('');
  const [policy, setPolicy] = useState('SKIP_EXISTING');
  const [status, setStatus] = useState('dang_dung');
  const [preview, setPreview] = useState(null);
  const [result, setResult] = useState(null);
  const [page, setPage] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const selection = useRef(0);

  async function chooseFile(event) {
    const file = event.target.files[0];
    const version = ++selection.current;
    setData(null); setPreview(null); setResult(null); setError(''); setPage(0);
    setFileName(file?.name || '');
    if (!file) return;
    if (file.size > 20 * 1024 * 1024) { setError('File tối đa 20 MB.'); return; }
    try {
      const parsed = JSON.parse(await file.text());
      if (!Array.isArray(parsed) || parsed.length === 0 || parsed.length > 10000) throw new Error('File cần chứa danh sách từ 1 đến 10.000 thủ tục.');
      if (selection.current === version) setData(parsed);
    } catch (failure) {
      if (selection.current === version) setError(failure instanceof SyntaxError ? 'File không phải JSON hợp lệ.' : failure.message);
    }
  }

  async function inspect() {
    setBusy(true); setError(''); setResult(null);
    try {
      setPreview(await request('/admin/imports/preview', { method: 'POST', body: { procedures: data, duplicatePolicy: policy, status } }));
      setPage(0);
    } catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }

  async function confirm() {
    setBusy(true); setError('');
    try {
      const expectedVersions = Object.fromEntries(preview.rows.map(row => [row.code, row.existingVersion ?? 0]));
      setResult(await request('/admin/imports/confirm', { method: 'POST', body: {
        request: { procedures: data, duplicatePolicy: policy, status }, expectedVersions,
      } }));
      setPreview(null);
    } catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }

  return <>
    <PageHeading title="Nhập dữ liệu thủ tục" eyebrow="DỮ LIỆU" description="Nhập file clean.json, kiểm tra dữ liệu và xác nhận trước khi lưu vào hệ thống." />
    <ol className="import-steps" aria-label="Các bước nhập dữ liệu">
      {[['Chọn dữ liệu', 'File JSON và cách xử lý'], ['Kiểm tra', 'Xem trước và xác nhận'], ['Hoàn tất', 'Kết quả và đồng bộ RAG']].map(([title, description], index) => {
        const step = result ? 2 : preview ? 1 : 0;
        return <li key={title} className={index < step ? 'complete' : undefined} aria-current={index === step ? 'step' : undefined}>
          <span className="step-marker">{index < step ? <Icon name="check" /> : index + 1}</span><div><strong>{title}</strong><small>{description}</small></div>
        </li>;
      })}
    </ol>
    <div className="import-layout">
    <section className="panel">
      <PanelHeading title="Chọn dữ liệu đầu vào" icon="upload" description="File JSON chứa danh sách thủ tục cần thêm hoặc cập nhật." />
      <fieldset className="import-options" disabled={busy}>
        <label className="file-picker"><Icon name="upload" /><span>File dữ liệu JSON</span><small>Định dạng .json · Tối đa 20 MB</small><input type="file" accept=".json,application/json" onChange={chooseFile} /></label>
        {data && <p className="file-selected">{fileName}: <strong>{data.length} thủ tục</strong>.</p>}
        <div className="form-grid">
        <label htmlFor="import-policy">Khi mã thủ tục đã có<select id="import-policy" value={policy} onChange={event => { setPolicy(event.target.value); setPreview(null); setResult(null); }}>
          <option value="SKIP_EXISTING">Bỏ qua thủ tục đã có</option><option value="UPDATE_EXISTING">Cập nhật thủ tục đã có</option>
        </select></label>
        <label htmlFor="import-status">Trạng thái sau khi nhập<select id="import-status" value={status} onChange={event => { setStatus(event.target.value); setPreview(null); setResult(null); }}>
          <option value="dang_dung">Đang áp dụng — đưa vào RAG</option><option value="nhap">Bản nháp — chưa đưa vào RAG</option>
        </select></label>
        </div>
        <div><button className="primary" disabled={!data} onClick={inspect}><Icon name="search" />{busy ? 'Đang xử lý…' : 'Xem trước dữ liệu'}</button></div>
      </fieldset>
      {error && <p className="error" role="alert">{error}</p>}
    </section>
    <aside className="panel import-guide" aria-label="Hướng dẫn nhập dữ liệu">
      <h2>Quy trình nhập dữ liệu</h2>
      <ol><li><strong>Chọn file</strong><br />Tải lên clean.json và chọn cách xử lý mã thủ tục đã có.</li>
        <li><strong>Kiểm tra trước khi lưu</strong><br />Xem số thủ tục thêm mới, cập nhật hoặc có lỗi.</li>
        <li><strong>Xác nhận nhập</strong><br />Lưu các dòng hợp lệ và theo dõi kết quả đồng bộ RAG.</li></ol>
      <p>Thủ tục đang áp dụng sẽ tự được đưa vào hàng đợi cập nhật RAG sau khi nhập thành công.</p>
    </aside>
    </div>
    {preview && <section className="panel" aria-label="Xem trước nhập dữ liệu">
      <PanelHeading title="Kết quả kiểm tra" icon="document" description="Đối chiếu dữ liệu trước khi xác nhận nhập." />
      <div className="import-summary">{[['Thêm mới', preview.createCount], ['Cập nhật', preview.updateCount], ['Bỏ qua', preview.skipCount], ['Có lỗi', preview.invalidCount]].map(([label, count]) => <div key={label}><span>{label}</span><strong>{count}</strong></div>)}</div>
      <p className="muted">Dòng có lỗi sẽ không được nhập. Cập nhật sẽ thay nội dung nguồn và các giấy tờ, cách nộp, lệ phí, trình tự của thủ tục bằng dữ liệu trong file.</p>
      <TableScroll label="Xem trước nhập dữ liệu"><table><thead><tr><th>Dòng</th><th>Mã</th><th>Tên thủ tục</th><th>Xử lý</th><th>Lỗi cần sửa</th></tr></thead>
        <tbody>{preview.rows.slice(page * 25, (page + 1) * 25).map(row => <tr key={row.rowNumber}>
          <td>{row.rowNumber}</td><td className="code">{row.code}</td><td><span className="cell-title" title={row.name}>{row.name}</span></td><td><span className="status">{actions[row.action]}</span></td>
          <td>{row.issues.map((issue, index) => <small key={index}>{issue.field}: {issue.message}</small>)}</td>
        </tr>)}</tbody></table></TableScroll>
      <Pagination data={{ page, size: 25, items: preview.rows.slice(page * 25, (page + 1) * 25), totalElements: preview.rows.length, totalPages: Math.ceil(preview.rows.length / 25) }} onPage={setPage} disabled={busy} />
      <div className="form-actions import-confirm"><button className="primary" disabled={busy || preview.createCount + preview.updateCount === 0} onClick={confirm}>
        {busy ? 'Đang nhập dữ liệu…' : `Xác nhận nhập ${preview.createCount + preview.updateCount} thủ tục`}
      </button></div>
    </section>}
    {result && <section className="panel" aria-label="Kết quả nhập dữ liệu">
      <PanelHeading title="Đã xử lý xong file" icon="check" />
      <p className="notice" role="status">Thêm mới: {result.createdCount} · Cập nhật: {result.updatedCount} · Bỏ qua: {result.skippedCount} · Không nhập được: {result.failedCount}.</p>
      <p>Dữ liệu đã lưu vào database. RAG sẽ được cập nhật tự động; khi AI-service tạm mất kết nối, hệ thống giữ yêu cầu và tự thử lại.</p>
      <Link className="button-link" to="/admin/ai-sources"><Icon name="refresh" />Xem trạng thái đồng bộ RAG</Link>
      {result.issues.length > 0 && <ul>{result.issues.map((issue, index) => <li key={index}>Dòng {issue.rowNumber} ({issue.procedureCode}): {issue.message}</li>)}</ul>}
    </section>}
  </>;
}
