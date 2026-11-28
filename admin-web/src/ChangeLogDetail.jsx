import { useEffect, useMemo, useRef, useState } from 'react';
import { actionLabels, collectChanges, describePath, displayValue } from './changeLogHelpers.js';
import { Icon, TableScroll } from './ui.jsx';

export function LogTime({ value }) {
  return value ? <time dateTime={value} title={value}>{new Date(value).toLocaleString('vi-VN')}</time> : '—';
}

export function LogActor({ entry }) {
  return <>{entry.administratorName || (entry.administratorId ? 'Không tìm thấy tài khoản' : 'Không lưu người thay đổi / tài khoản đã xóa')}
    {entry.administratorId && <small>ID admin: {entry.administratorId}</small>}</>;
}

export function LogTarget({ entry }) {
  return <>{entry.tableName === 'thu_tuc' ? 'Thủ tục' : entry.tableName}<small>ID bản ghi: {entry.recordId}</small></>;
}

export function ChangeLogDetail({ request, id, revision, close }) {
  const [entry, setEntry] = useState(null);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [limit, setLimit] = useState(50);
  const heading = useRef(null);

  useEffect(() => {
    const controller = new AbortController();
    setEntry(null); setError(''); setLimit(50);
    request(`/admin/change-logs/${encodeURIComponent(id)}`, { signal: controller.signal })
      .then(data => { if (!controller.signal.aborted) setEntry(data); })
      .catch(failure => { if (!controller.signal.aborted) setError(failure.message); });
    return () => controller.abort();
  }, [request, id, revision, attempt]);

  useEffect(() => { if (entry || error) heading.current?.focus(); }, [entry, error]);
  const changes = useMemo(() => entry ? collectChanges(entry.before ?? undefined, entry.after ?? undefined) : [], [entry]);

  return <section id="history-detail" className="panel history-detail" aria-labelledby="history-detail-title">
    <div className="section-heading">
      <h2 id="history-detail-title" ref={heading} tabIndex={-1}>Chi tiết thay đổi #{id}</h2>
      <button className="button-small" onClick={close}><Icon name="close" />Đóng chi tiết</button>
    </div>
    {error ? <><p className="error" role="alert">{error}</p><button onClick={() => setAttempt(value => value + 1)}>Thử tải chi tiết lại</button></> :
      !entry ? <p role="status">Đang tải chi tiết…</p> : <>
        <dl className="history-meta">
          <div><dt>Người thay đổi</dt><dd><LogActor entry={entry} /></dd></div>
          <div><dt>Dữ liệu</dt><dd><LogTarget entry={entry} /></dd></div>
          <div><dt>Thao tác</dt><dd>{entry.action === 'xoa' && entry.tableName === 'thu_tuc' ? 'Ngừng áp dụng' : actionLabels[entry.action] ?? entry.action}</dd></div>
          <div><dt>Thời gian</dt><dd><LogTime value={entry.createdAt} /></dd></div>
        </dl>
        <h3>Nội dung thay đổi</h3>
        <p className="muted">Chỉ hiển thị trường có thay đổi trong hai bản đã lưu. Các mục trong danh sách được đối chiếu theo thứ tự.</p>
        {!changes.length ? <p>Không có khác biệt trong dữ liệu trước và sau đã lưu.</p> : <>
          <TableScroll label="So sánh dữ liệu trước và sau"><table className="history-diff">
            <caption className="sr-only">So sánh dữ liệu trước và sau thay đổi</caption>
            <thead><tr><th scope="col">Trường thay đổi</th><th scope="col">Trước thay đổi</th><th scope="col">Sau thay đổi</th></tr></thead>
            <tbody>{changes.slice(0, limit).map(change => <tr key={JSON.stringify(change.path)}>
              <th scope="row">{describePath(change.path)}</th>
              <td><pre>{displayValue(change.before)}</pre></td>
              <td><pre>{displayValue(change.after)}</pre></td>
            </tr>)}</tbody>
          </table></TableScroll>
          <div className="form-actions history-more"><span>Hiển thị {Math.min(limit, changes.length)}/{changes.length} trường thay đổi</span>
            {changes.length > limit && <button onClick={() => setLimit(value => value + 50)}>Xem thêm trường thay đổi</button>}
          </div>
        </>}
        <details className="history-snapshots"><summary>Xem dữ liệu đầy đủ trước / sau</summary>
          <div className="account-grid">
            {['before', 'after'].map(side => <section key={side}>
              <h3>{side === 'before' ? 'Dữ liệu trước' : 'Dữ liệu sau'}</h3>
              {entry[side] == null ? <p className="muted">Không có bản dữ liệu được lưu.</p> : <pre>{JSON.stringify(entry[side], null, 2)}</pre>}
            </section>)}
          </div>
        </details>
      </>}
  </section>;
}
