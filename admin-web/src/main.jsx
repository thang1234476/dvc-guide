import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { api, basicCredentials } from './api.js';
import { levels, ProcedureEditor, statuses } from './ProcedureEditor.jsx';
import './styles.css';

function Login({ onLogin }) {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const authorization = basicCredentials(form.get('email').trim(), form.get('password'));
    setBusy(true);
    setError('');
    try {
      const profile = await api('/admin/me', { authorization });
      onLogin({ authorization, profile });
    } catch (failure) {
      setError(failure.message);
      setBusy(false);
    }
  }

  return (
    <main className="login">
      <section className="panel" aria-labelledby="login-title">
        <p className="brand">DVC Guide</p>
        <h1 id="login-title">Đăng nhập quản trị</h1>
        <form onSubmit={submit}>
          <label>Email<input name="email" type="email" autoComplete="username" required maxLength={255} /></label>
          <label>Mật khẩu<input name="password" type="password" autoComplete="current-password" required maxLength={72} /></label>
          {error && <p className="error" role="alert">{error}</p>}
          <button className="primary" disabled={busy}>{busy ? 'Đang đăng nhập…' : 'Đăng nhập'}</button>
        </form>
      </section>
    </main>
  );
}

function Workspace({ session, logout }) {
  const { authorization, profile } = session;
  const [search, setSearch] = useState({ keyword: '', page: 0, revision: 0 });
  const [rows, setRows] = useState(null);
  const [fields, setFields] = useState([]);
  const [fieldsReady, setFieldsReady] = useState(false);
  const [editor, setEditor] = useState(null);
  const [listError, setListError] = useState('');
  const [editorError, setEditorError] = useState('');
  const [notice, setNotice] = useState('');
  const pendingEdit = useRef(null);

  useEffect(() => {
    const controller = new AbortController();
    const params = new URLSearchParams({ keyword: search.keyword, page: search.page });
    setRows(null);
    setListError('');
    api(`/admin/procedures?${params}`, { authorization, signal: controller.signal }).then(setRows).catch((failure) => {
      if (!controller.signal.aborted) setListError(failure.message);
    });
    return () => controller.abort();
  }, [authorization, search]);

  useEffect(() => {
    const controller = new AbortController();
    api('/catalog/fields', { signal: controller.signal }).then((items) => {
      setFields(items);
      setFieldsReady(true);
    }).catch((failure) => {
      if (!controller.signal.aborted) setEditorError(failure.message);
    });
    return () => {
      controller.abort();
      pendingEdit.current?.abort();
    };
  }, []);

  async function edit(id) {
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
      const detail = await api(`/admin/procedures/${id}`, { authorization, signal: controller.signal });
      if (!controller.signal.aborted) setEditor({ detail });
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
    await api(id ? `/admin/procedures/${id}` : '/admin/procedures',
      { authorization, body, method: id ? 'PUT' : 'POST' });
    completed('Đã lưu thủ tục.');
  }

  async function retire() {
    const { id, version } = editor.detail.procedure;
    await api(`/admin/procedures/${id}?version=${version}`, { authorization, method: 'DELETE' });
    completed('Đã ngừng áp dụng thủ tục.');
  }

  return (
    <>
      <header>
        <div className="shell topbar">
          <span className="brand">DVC Guide</span>
          <div className="account">
            <span>{profile.displayName || profile.email}</span>
            <button onClick={logout}>Đăng xuất</button>
          </div>
        </div>
      </header>
      <main className="shell workspace">
        <div className="section-heading">
          <h1>Quản lý thủ tục</h1>
          <button className="primary" disabled={Boolean(editor) || !fieldsReady} onClick={() => edit(null)}>Thêm thủ tục</button>
        </div>
        {notice && <p className="notice" role="status">{notice}</p>}
        {editorError && <p className="error" role="alert">{editorError}</p>}
        {editor?.loading && <p role="status">Đang tải thủ tục…</p>}
        {editor && !editor.loading &&
          <ProcedureEditor key={editor.detail?.procedure.id ?? 'new'} detail={editor.detail} fields={fields}
            save={save} retire={retire} close={() => setEditor(null)} />}
        {!editor && <section className="panel" aria-label="Danh sách thủ tục">
          <form className="search" onSubmit={(event) => {
            event.preventDefault();
            const keyword = new FormData(event.currentTarget).get('keyword').trim();
            setSearch((previous) => ({ keyword, page: 0, revision: previous.revision + 1 }));
          }}>
            <input type="search" name="keyword" maxLength={250} aria-label="Tên hoặc mã thủ tục" placeholder="Tên hoặc mã thủ tục" />
            <button>Tìm kiếm</button>
          </form>
          {listError ? <p className="error" role="alert">{listError}</p> :
            rows === null ? <p className="muted" role="status">Đang tải danh sách…</p> :
            rows.items.length === 0 ? <p className="muted">Không tìm thấy thủ tục.</p> :
            <div className="table-wrap">
              <table>
                <thead><tr><th>Mã thủ tục</th><th>Tên thủ tục</th><th>Cấp thực hiện</th><th>Trạng thái</th><th><span className="sr-only">Thao tác</span></th></tr></thead>
                <tbody>{rows.items.map((row) => <tr key={row.id}>
                  <td className="code">{row.code}</td>
                  <td>{row.name}{row.fields.length > 0 && <small>{row.fields.map(({ name }) => name).join(' · ')}</small>}</td>
                  <td>{levels[row.level] ?? 'Chưa xác định'}</td>
                  <td><span className={`status ${row.status}`}>{statuses[row.status]}</span></td>
                  <td><button disabled={!fieldsReady} onClick={() => edit(row.id)} aria-label={`Sửa ${row.name}`}>Sửa</button></td>
                </tr>)}</tbody>
              </table>
            </div>}
          {rows?.totalPages > 1 && <div className="pagination">
            <span>Trang {rows.page + 1}/{rows.totalPages}</span>
            <button disabled={rows.page === 0} onClick={() => setSearch({ ...search, page: rows.page - 1 })}>Trang trước</button>
            <button disabled={rows.page + 1 >= rows.totalPages} onClick={() => setSearch({ ...search, page: rows.page + 1 })}>Trang sau</button>
          </div>}
        </section>}
      </main>
    </>
  );
}

function App() {
  const [session, setSession] = useState(null);
  return session ? <Workspace session={session} logout={() => setSession(null)} /> : <Login onLogin={setSession} />;
}

createRoot(document.getElementById('root')).render(<App />);
