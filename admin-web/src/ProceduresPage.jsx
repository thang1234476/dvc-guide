import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router';
import { levels, ProcedureEditor, statuses } from './ProcedureEditor.jsx';
import { EmptyState, Icon, PageHeading, Pagination, TableScroll } from './ui.jsx';
import { downloadJson } from './procedureContent.js';

export function ProceduresPage({ request }) {
  const [search, setSearch] = useState({ keyword: '', page: 0, revision: 0 });
  const [rows, setRows] = useState(null);
  const [fields, setFields] = useState([]);
  const [fieldsReady, setFieldsReady] = useState(false);
  const [editor, setEditor] = useState(null);
  const [listError, setListError] = useState('');
  const [editorError, setEditorError] = useState('');
  const [notice, setNotice] = useState('');
  const [exporting, setExporting] = useState(false);
  const pendingEdit = useRef(null);

  useEffect(() => {
    const controller = new AbortController();
    const params = new URLSearchParams({ keyword: search.keyword, page: search.page });
    setRows(null);
    setListError('');
    request(`/admin/procedures?${params}`, { signal: controller.signal }).then(setRows).catch((failure) => {
      if (!controller.signal.aborted) setListError(failure.message);
    });
    return () => controller.abort();
  }, [request, search]);

  useEffect(() => {
    const controller = new AbortController();
    request('/catalog/fields', { signal: controller.signal }).then((items) => {
      setFields(items);
      setFieldsReady(true);
    }).catch((failure) => {
      if (!controller.signal.aborted) setEditorError(failure.message);
    });
    return () => {
      controller.abort();
      pendingEdit.current?.abort();
    };
  }, [request]);

  async function edit(id, readOnly = false) {
    pendingEdit.current?.abort();
    setEditorError('');
    setNotice('');
    if (id === null) {
      setEditor({ detail: null });
      return;
    }
    const controller = new AbortController();
    pendingEdit.current = controller;
    setEditor({ loading: true });
    try {
      const [detail, cleanData] = await Promise.all([
        request(`/admin/procedures/${id}`, { signal: controller.signal }),
        request(`/admin/procedures/${id}/content`, { signal: controller.signal }),
      ]);
      if (!controller.signal.aborted) setEditor({ detail: { ...detail, cleanData }, readOnly });
    } catch (failure) {
      if (!controller.signal.aborted) {
        setEditorError(failure.message);
        setEditor(null);
      }
    }
  }

  function completed(message) {
    setEditor(null);
    setNotice(message);
    setSearch((previous) => ({ ...previous, page: 0, revision: previous.revision + 1 }));
  }

  async function save(body) {
    const id = editor.detail?.procedure.id;
    await request(id ? `/admin/procedures/${id}` : '/admin/procedures',
      { body, method: id ? 'PUT' : 'POST' });
    completed('Đã lưu thủ tục. Yêu cầu cập nhật RAG đã được ghi nhận.');
  }

  async function retire() {
    const { id, version } = editor.detail.procedure;
    await request(`/admin/procedures/${id}?version=${version}`, { method: 'DELETE' });
    completed('Đã ngừng áp dụng thủ tục và ghi yêu cầu gỡ khỏi RAG.');
  }

  async function exportAll(activeOnly) {
    setEditorError(''); setExporting(true);
    try { await downloadJson(request, `/admin/procedures/export?activeOnly=${activeOnly}`); }
    catch (failure) { setEditorError(failure.message); }
    finally { setExporting(false); }
  }

  return (
    <>
      <PageHeading title="Quản lý thủ tục" eyebrow="NỘI DUNG" description="Tra cứu, chỉnh sửa và quản lý các thủ tục hành chính trong hệ thống.">
        <details className="export-menu"><summary className="button-link"><Icon name="download" />{exporting ? 'Đang xuất…' : 'Xuất JSON'}</summary>
          <div className="export-options"><button disabled={exporting} onClick={() => exportAll(false)}>Tất cả thủ tục<small>Gồm bản nháp và thủ tục ngừng áp dụng</small></button>
            <button disabled={exporting} onClick={() => exportAll(true)}>Chỉ thủ tục đang áp dụng<small>Dữ liệu đang được dùng cho tra cứu và RAG</small></button></div>
        </details>
        <button className="primary" disabled={Boolean(editor) || !fieldsReady} onClick={() => edit(null)}><Icon name="plus" />Thêm thủ tục</button>
      </PageHeading>
      {notice && <p className="notice" role="status">{notice}</p>}
      {editorError && <p className="error" role="alert">{editorError}</p>}
      {editor?.loading && <p role="status">Đang tải thủ tục…</p>}
      {editor && !editor.loading &&
        <ProcedureEditor key={editor.detail?.procedure.id ?? 'new'} detail={editor.detail} fields={fields}
          save={save} retire={retire} close={() => setEditor(null)} readOnly={editor.readOnly}
          onEdit={() => setEditor(previous => ({ ...previous, readOnly: false }))}
          exportJson={() => downloadJson(request, `/admin/procedures/${editor.detail.procedure.id}/export`)} />}
      {!editor && <section className="panel" aria-label="Danh sách thủ tục">
        <div className="list-toolbar">
          <div className="list-toolbar-heading"><h2>Danh sách thủ tục</h2>{rows && <span className="count-badge">{rows.totalElements} thủ tục</span>}</div>
        <form className="search" onSubmit={(event) => {
          event.preventDefault();
          const keyword = new FormData(event.currentTarget).get('keyword').trim();
          setSearch((previous) => ({ keyword, page: 0, revision: previous.revision + 1 }));
        }}>
          <div className="search-input"><Icon name="search" /><input type="search" name="keyword" maxLength={250} aria-label="Tên hoặc mã thủ tục" placeholder="Tìm theo tên hoặc mã thủ tục…" /></div>
          <button>Tìm kiếm</button>
        </form>
        </div>
        {listError ? <p className="error" role="alert">{listError}</p> :
          rows === null ? <p className="muted" role="status">Đang tải danh sách…</p> :
          rows.items.length === 0 ? <EmptyState title="Không tìm thấy thủ tục." description="Thử tìm bằng tên, mã khác hoặc thêm thủ tục mới vào hệ thống." icon="search" /> :
          <TableScroll label="Danh sách thủ tục">
            <table className="procedures-table">
              <colgroup><col className="col-code" /><col /><col className="col-level" /><col className="col-status" /><col className="col-actions" /></colgroup>
              <thead><tr><th>Mã thủ tục</th><th>Tên thủ tục</th><th>Cấp thực hiện</th><th>Trạng thái</th><th><span className="sr-only">Thao tác</span></th></tr></thead>
              <tbody>{rows.items.map((row) => <tr key={row.id}>
                <td className="code">{row.code}</td>
                <td><button className="cell-title procedure-title" title={row.name} onClick={() => edit(row.id, true)} aria-label={`Xem ${row.name}`}>{row.name}</button>{row.fields.length > 0 && <div className="cell-tags">{row.fields.map(field => <span className="cell-tag" key={field.id}>{field.name}</span>)}</div>}</td>
                <td>{levels[row.level] ?? 'Chưa xác định'}</td>
                <td><span className={`status ${row.status}`}>{statuses[row.status]}</span></td>
                <td><div className="cell-actions"><button className="button-small" disabled={!fieldsReady} onClick={() => edit(row.id)} aria-label={`Sửa ${row.name}`}><Icon name="edit" />Sửa</button>
                  <Link className="button-link button-small" to={`/admin/change-logs?tableName=thu_tuc&recordId=${row.id}`} aria-label={`Xem lịch sử ${row.name}`}><Icon name="history" />Lịch sử</Link>
                </div></td>
              </tr>)}</tbody>
            </table>
          </TableScroll>}
        <Pagination data={rows} onPage={page => setSearch({ ...search, page })} />
      </section>}
    </>
  );
}
