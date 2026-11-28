import { useEffect, useState } from 'react';
import { EmptyState, Icon, PageHeading, Pagination, PanelHeading, TableScroll } from './ui.jsx';

const labels = { NOT_INDEXED: 'Chưa đồng bộ', PENDING: 'Chờ đồng bộ', PROCESSING: 'Đang đồng bộ',
  UP_TO_DATE: 'Đã đồng bộ', OUTDATED: 'Cần cập nhật', EXCLUDED: 'Đã gỡ khỏi RAG', FAILED: 'Đồng bộ lỗi' };

export function RagSourcesPage({ request }) {
  const [query, setQuery] = useState({ page: 0, revision: 0 });
  const [rows, setRows] = useState(null);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    let pending = false;
    async function load() {
      if (pending) return;
      pending = true;
      try {
        const data = await request(`/admin/rag/sources?page=${query.page}&size=20`, { signal: controller.signal });
        if (!controller.signal.aborted) { setRows(data); setError(''); }
      } catch (failure) { if (!controller.signal.aborted) setError(failure.message); }
      finally { pending = false; }
    }
    setRows(null); load();
    const interval = setInterval(load, 5000);
    return () => { controller.abort(); clearInterval(interval); };
  }, [request, query]);

  async function retry(targets) {
    setBusy(true); setError(''); setNotice('');
    try {
      await request('/admin/rag/sync', { method: 'POST', body: { targets: targets.map(row => ({ procedureId: row.procedureId, expectedVersion: row.procedureVersion })) } });
      setNotice('Đã đưa vào hàng đợi. Danh sách tự cập nhật mỗi 5 giây.');
      setQuery(previous => ({ ...previous, revision: previous.revision + 1 }));
    } catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }

  return <>
    <PageHeading title="Đồng bộ nguồn RAG" eyebrow="DỮ LIỆU AI" description="Theo dõi dữ liệu thủ tục được sử dụng để tìm kiếm và trả lời câu hỏi.">
      <button disabled={busy || !rows?.items.length} onClick={() => retry(rows.items)}><Icon name="refresh" />Đồng bộ lại trang này</button>
    </PageHeading>
    {error && <p className="error" role="alert">{error}</p>}
    {notice && <p className="notice" role="status">{notice}</p>}
    <section className="panel" aria-label="Trạng thái đồng bộ RAG">
      <PanelHeading title="Trạng thái nguồn dữ liệu" icon="refresh">{rows && <span className="count-badge">{rows.totalElements} thủ tục</span>}</PanelHeading>
      <div className="sync-info"><span>Thủ tục đang áp dụng được dùng để trả lời. Bản nháp và thủ tục ngừng áp dụng được gỡ khỏi RAG.</span><span><Icon name="clock" />Tự cập nhật mỗi 5 giây</span></div>
      {!rows ? <p role="status">Đang tải trạng thái…</p> : rows.items.length === 0 ? <EmptyState title="Chưa có nguồn dữ liệu" description="Nhập dữ liệu hoặc tạo thủ tục để bắt đầu đồng bộ." icon="refresh" /> : <>
        <TableScroll label="Trạng thái nguồn dữ liệu RAG"><table className="rag-table">
          <colgroup><col /><col className="col-version" /><col className="col-sync" /><col className="col-chunks" /><col className="col-actions" /></colgroup>
          <thead><tr><th>Thủ tục</th><th>Phiên bản</th><th>Đồng bộ</th><th>Số đoạn</th><th><span className="sr-only">Thao tác</span></th></tr></thead>
          <tbody>{rows.items.map(row => <tr key={row.procedureId}>
            <td><span className="cell-title" title={row.name}>{row.name}</span><small>{row.code}</small></td>
            <td className="code">DB: {row.procedureVersion}<small>RAG: {row.indexedVersion ?? 'Chưa có'}</small></td>
            <td><span className={`status sync-${row.status}`}>{labels[row.status] ?? row.status}</span>
              {row.message && <small>{row.message}</small>}
              {row.status === 'FAILED' && row.nextAttemptAt && <small>Thử lại: {new Date(row.nextAttemptAt).toLocaleTimeString('vi-VN')}</small>}
            </td>
            <td>{row.chunkCount}</td>
            <td><button className="button-small" disabled={busy || row.status === 'PROCESSING'} onClick={() => retry([row])} aria-label={`Đồng bộ ${row.code}`}><Icon name="refresh" />Đồng bộ lại</button></td>
          </tr>)}</tbody></table></TableScroll>
        <Pagination data={rows} onPage={page => setQuery({ ...query, page })} disabled={busy} />
      </>}
    </section>
  </>;
}
