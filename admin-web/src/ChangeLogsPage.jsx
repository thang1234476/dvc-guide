import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'react-router';
import { ChangeLogDetail, LogActor, LogTarget, LogTime } from './ChangeLogDetail.jsx';
import { actionLabels, localDateTime } from './changeLogHelpers.js';
import { EmptyState, Icon, PageHeading, Pagination, TableScroll } from './ui.jsx';

const filterNames = ['administratorId', 'tableName', 'recordId', 'action', 'from', 'to'];

export function ChangeLogsPage({ request }) {
  const [params, setParams] = useSearchParams();
  const [rows, setRows] = useState(null);
  const [actors, setActors] = useState([]);
  const [actorsError, setActorsError] = useState('');
  const [error, setError] = useState('');
  const [filterError, setFilterError] = useState('');
  const [revision, setRevision] = useState(0);
  const opener = useRef(null);
  const selectedId = params.get('logId');
  const filters = new URLSearchParams();
  for (const name of filterNames) if (params.get(name)) filters.set(name, params.get(name));
  const filterKey = filters.toString();
  filters.set('page', params.get('page') ?? '0');
  filters.set('size', '20');
  const query = filters.toString();

  useEffect(() => {
    const controller = new AbortController();
    setRows(null); setError('');
    request(`/admin/change-logs?${query}`, { signal: controller.signal })
      .then(data => { if (!controller.signal.aborted) setRows(data); })
      .catch(failure => { if (!controller.signal.aborted) setError(failure.message); });
    return () => controller.abort();
  }, [request, query, revision]);

  useEffect(() => {
    const controller = new AbortController();
    setActorsError('');
    request('/admin/change-logs/administrators', { signal: controller.signal })
      .then(data => { if (!controller.signal.aborted) setActors(data); })
      .catch(failure => { if (!controller.signal.aborted) setActorsError(failure.message); });
    return () => controller.abort();
  }, [request, revision]);

  useEffect(() => { setFilterError(''); }, [filterKey]);

  function apply(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const next = new URLSearchParams();
    const from = form.get('from');
    const to = form.get('to');
    if (from && to && new Date(from) > new Date(to)) {
      setFilterError('Thời điểm bắt đầu phải trước hoặc bằng thời điểm kết thúc.');
      return;
    }
    setFilterError('');
    for (const name of filterNames) {
      const value = form.get(name).trim();
      if (value) next.set(name, name === 'from' || name === 'to' ? new Date(value).toISOString() : value);
    }
    setParams(next);
    setRevision(value => value + 1);
  }

  function pageTo(page) {
    const next = new URLSearchParams(params);
    next.set('page', page); next.delete('logId');
    setParams(next);
  }

  const actorId = params.get('administratorId') ?? '';
  return <>
    <PageHeading title="Lịch sử thay đổi" eyebrow="THEO DÕI HOẠT ĐỘNG" description="Xem ai đã tạo, sửa hoặc ngừng áp dụng thủ tục, gồm cả các lần nhập dữ liệu JSON.">
      <button onClick={() => setRevision(value => value + 1)}><Icon name="refresh" />Làm mới</button>
    </PageHeading>
    <details className="panel history-filters" aria-label="Bộ lọc lịch sử" open>
      <summary><Icon name="filter" />Bộ lọc lịch sử{filterNames.filter(name => params.get(name)).length > 0 && <span className="count-badge">{filterNames.filter(name => params.get(name)).length} bộ lọc</span>}<Icon name="right" className="filter-toggle" /></summary>
      <form key={filterKey} onSubmit={apply}>
        <div className="history-filter-grid">
          <label>Người thay đổi<select name="administratorId" defaultValue={actorId}>
            <option value="">Tất cả người thay đổi</option>
            {actorId && !actors.some(actor => String(actor.id) === actorId) && <option value={actorId}>ID admin: {actorId}</option>}
            {actors.map(actor => <option key={actor.id} value={actor.id}>{actor.name} (#{actor.id})</option>)}
          </select></label>
          <label>Thao tác<select name="action" defaultValue={params.get('action') ?? ''}>
            <option value="">Tất cả thao tác</option>
            {Object.entries(actionLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select></label>
          <label>Bảng dữ liệu<input name="tableName" placeholder="Ví dụ: thu_tuc" maxLength={64} defaultValue={params.get('tableName') ?? ''} /></label>
          <label>ID bản ghi<input name="recordId" placeholder="Ví dụ: 123" maxLength={64} defaultValue={params.get('recordId') ?? ''} /></label>
          <label>Từ thời điểm<input name="from" type="datetime-local" step="1" defaultValue={localDateTime(params.get('from'))} /></label>
          <label>Đến thời điểm<input name="to" type="datetime-local" step="1" defaultValue={localDateTime(params.get('to'))} /></label>
        </div>
        {filterError && <p className="error" role="alert">{filterError}</p>}
        <div className="filter-footer"><p className="muted">Thời gian theo múi giờ trình duyệt ({Intl.DateTimeFormat().resolvedOptions().timeZone}). Có thể để trống các bộ lọc.</p>
        <div className="form-actions"><button className="primary"><Icon name="filter" />Lọc lịch sử</button>
          <button type="button" onClick={() => { setFilterError(''); setParams({}); setRevision(value => value + 1); }}>Xóa bộ lọc</button>
        </div></div>
      </form>
      {actorsError && <p className="error" role="alert">Không tải được danh sách người thay đổi: {actorsError} Bấm Làm mới để thử lại.</p>}
    </details>
    {selectedId && <ChangeLogDetail request={request} id={selectedId} revision={revision} close={() => {
      const next = new URLSearchParams(params); next.delete('logId'); setParams(next);
      opener.current?.focus();
    }} />}
    <section className="panel" aria-label="Danh sách lịch sử thay đổi">
      <div className="list-toolbar"><h2>Nhật ký thay đổi</h2>{rows && <span className="count-badge">{rows.totalElements} lượt thay đổi</span>}</div>
      {error ? <><p className="error" role="alert">{error}</p><button onClick={() => setRevision(value => value + 1)}>Thử tải lịch sử lại</button></> :
        !rows ? <p role="status">Đang tải lịch sử…</p> : <>
          <p className="muted list-summary" role="status">Tìm thấy {rows.totalElements} lượt thay đổi. Mới nhất hiển thị trước.</p>
          {!rows.items.length ? <EmptyState title="Không có lịch sử phù hợp." description="Thử xóa bộ lọc hoặc tạo / chỉnh sửa thủ tục trước." icon="history" /> :
            <TableScroll label="Nhật ký thay đổi"><table className="history-list">
              <caption className="sr-only">Danh sách lịch sử thay đổi, mới nhất trước</caption>
              <thead><tr><th scope="col">Thời gian</th><th scope="col">Người thay đổi</th><th scope="col">Dữ liệu</th><th scope="col">Thao tác</th><th scope="col"><span className="sr-only">Chi tiết</span></th></tr></thead>
              <tbody>{rows.items.map(entry => <tr key={entry.id} className={selectedId === String(entry.id) ? 'history-selected' : undefined}>
                <td><LogTime value={entry.createdAt} /><small>Nhật ký #{entry.id}</small></td>
                <td><LogActor entry={entry} /></td><td><LogTarget entry={entry} /></td>
                <td><span className={`status history-${entry.action}`}>{entry.action === 'xoa' && entry.tableName === 'thu_tuc' ? 'Ngừng áp dụng' : actionLabels[entry.action] ?? entry.action}</span></td>
                <td><button className="button-small" aria-label={`Xem chi tiết thay đổi #${entry.id}`} aria-expanded={selectedId === String(entry.id)} aria-controls={selectedId === String(entry.id) ? 'history-detail' : undefined} onClick={event => {
                  opener.current = event.currentTarget;
                  const next = new URLSearchParams(params); next.set('logId', entry.id); setParams(next);
                }}>Xem chi tiết</button></td>
              </tr>)}</tbody>
            </table></TableScroll>}
          <Pagination data={rows} onPage={pageTo} />
        </>}
    </section>
  </>;
}
