import { useEffect, useState } from 'react';
import { roleLabels, validateNewPassword } from './accountHelpers.js';
import { EmptyState, Icon, PageHeading, Pagination, PanelHeading, TableScroll } from './ui.jsx';

function CreateAccountForm({ request, onCreated, onCancel }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const password = form.get('password');
    const validationError = validateNewPassword(password, form.get('confirmPassword'));
    setError(validationError);
    if (validationError) return;
    setBusy(true);
    try {
      const created = await request('/admin/accounts', {
        method: 'POST',
        body: { email: form.get('email').trim(), displayName: form.get('displayName').trim(), password },
      });
      onCreated(created);
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="panel account-editor" aria-labelledby="create-account-title">
      <h2 id="create-account-title">Tạo tài khoản admin</h2>
      <p className="muted">Tài khoản mới có quyền quản trị. Hãy cấp thông tin đăng nhập cho người được giao quản lý.</p>
      <form className="account-form create-account-form" onSubmit={submit}>
        <fieldset disabled={busy}>
          <label>Email<input name="email" type="email" autoComplete="off" required maxLength={255} /></label>
          <label>Tên hiển thị<input name="displayName" autoComplete="off" maxLength={255} /></label>
          <label>Mật khẩu ban đầu<input name="password" type="password" autoComplete="new-password" required minLength={12} maxLength={72} aria-describedby="create-password-help" /></label>
          <label>Nhập lại mật khẩu<input name="confirmPassword" type="password" autoComplete="new-password" required maxLength={72} /></label>
          <small className="full" id="create-password-help">Ít nhất 12 ký tự, tối đa 72 byte. Người được cấp tài khoản có thể tự đổi mật khẩu trong mục Tài khoản của tôi.</small>
        </fieldset>
        {error && <p className="error" role="alert">{error}</p>}
        <div className="form-actions">
          <button className="primary" disabled={busy}>{busy ? 'Đang tạo…' : 'Tạo tài khoản'}</button>
          <button type="button" disabled={busy} onClick={onCancel}>Hủy</button>
        </div>
      </form>
    </section>
  );
}

export function AdminAccountsPage({ request }) {
  const [query, setQuery] = useState({ page: 0, revision: 0 });
  const [rows, setRows] = useState(null);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    setRows(null);
    setError('');
    request(`/admin/accounts?page=${query.page}&size=20`, { signal: controller.signal })
      .then(setRows).catch((failure) => {
        if (!controller.signal.aborted) setError(failure.message);
      });
    return () => controller.abort();
  }, [request, query]);

  function created(account) {
    setCreating(false);
    setNotice(`Đã tạo tài khoản ${account.email}. Có thể đăng nhập ngay bằng mật khẩu vừa cấp.`);
    setQuery((previous) => ({ page: 0, revision: previous.revision + 1 }));
  }

  return (
    <>
      <PageHeading title="Quản lý tài khoản admin" eyebrow="QUẢN TRỊ" description="Quản lý tài khoản và cấp quyền truy cập cho người cùng quản trị hệ thống.">
        {!creating && <button className="primary" onClick={() => { setNotice(''); setCreating(true); }}><Icon name="plus" />Thêm admin</button>}
      </PageHeading>
      {notice && <p className="notice" role="status">{notice}</p>}
      {creating && <CreateAccountForm request={request} onCreated={created} onCancel={() => setCreating(false)} />}
      <section className="panel" aria-label="Danh sách tài khoản admin">
        <PanelHeading title="Tài khoản quản trị" icon="users" description="Danh sách tài khoản có quyền truy cập trang quản trị.">
          {rows && <span className="count-badge">{rows.totalElements} tài khoản</span>}
        </PanelHeading>
        {error ? <>
          <p className="error" role="alert">{error}</p>
          <button onClick={() => setQuery((previous) => ({ ...previous, revision: previous.revision + 1 }))}>Thử lại</button>
        </> : rows === null ? <p className="muted" role="status">Đang tải tài khoản…</p> : <>
          {rows.items.length === 0 ? <EmptyState title="Chưa có tài khoản trong trang này." icon="users" /> : <TableScroll label="Danh sách tài khoản admin">
            <table>
              <thead><tr><th>Email</th><th>Tên hiển thị</th><th>Vai trò</th><th>Trạng thái</th><th>Ngày tạo</th></tr></thead>
              <tbody>{rows.items.map((account) => <tr key={account.id}>
                <td>{account.email}</td>
                <td>{account.displayName || 'Chưa đặt tên'}</td>
                <td>{roleLabels[account.role] ?? account.role}</td>
                <td><span className={`status ${account.active ? 'dang_dung' : 'ngung'}`}>{account.active ? 'Hoạt động' : 'Đã khóa'}</span></td>
                <td className="code">{account.createdAt ? new Date(account.createdAt).toLocaleDateString('vi-VN') : '—'}</td>
              </tr>)}</tbody>
            </table>
          </TableScroll>}
          <Pagination data={rows} onPage={page => setQuery({ ...query, page })} />
        </>}
      </section>
    </>
  );
}
