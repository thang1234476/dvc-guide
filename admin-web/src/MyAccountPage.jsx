import { useState } from 'react';
import { roleLabels, validateNewPassword } from './accountHelpers.js';
import { Icon, PageHeading } from './ui.jsx';

function ProfileForm({ request, profile, onUpdated }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  async function submit(event) {
    event.preventDefault();
    const displayName = new FormData(event.currentTarget).get('displayName').trim();
    setError('');
    setNotice('');
    if (!displayName) {
      setError('Vui lòng nhập tên hiển thị.');
      return;
    }
    setBusy(true);
    try {
      const updated = await request('/admin/me', { method: 'PUT', body: { displayName } });
      onUpdated(updated);
      setNotice('Đã cập nhật tên hiển thị.');
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="panel" aria-labelledby="profile-title">
      <h2 id="profile-title">Thông tin tài khoản</h2>
      <div className="profile-identity"><span className="profile-avatar"><Icon name="user" /></span>
        <div><p>{profile.displayName || profile.email}</p><small>{roleLabels[profile.role] ?? profile.role}</small></div>
      </div>
      <dl className="account-details">
        <div><dt>Email đăng nhập</dt><dd>{profile.email}</dd></div>
        <div><dt>Vai trò</dt><dd>{roleLabels[profile.role] ?? profile.role}</dd></div>
      </dl>
      <form className="account-form" onSubmit={submit}>
        <fieldset disabled={busy}>
          <label>Tên hiển thị<input name="displayName" defaultValue={profile.displayName ?? ''} required maxLength={255} autoComplete="name" /></label>
        </fieldset>
        {error && <p className="error" role="alert">{error}</p>}
        {notice && <p className="notice" role="status">{notice}</p>}
        <div className="form-actions"><button className="primary" disabled={busy}><Icon name="check" />{busy ? 'Đang lưu…' : 'Lưu thông tin'}</button></div>
      </form>
    </section>
  );
}

function PasswordForm({ request, onChanged }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    const currentPassword = form.get('currentPassword');
    const newPassword = form.get('newPassword');
    const confirmPassword = form.get('confirmPassword');
    const validationError = validateNewPassword(newPassword, confirmPassword);
    setError(validationError);
    if (validationError) return;
    setBusy(true);
    try {
      await request('/admin/me/password', { method: 'POST', body: { currentPassword, newPassword, confirmPassword } });
      formElement.reset();
      onChanged();
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="panel" aria-labelledby="password-title">
      <h2 id="password-title">Đổi mật khẩu</h2>
      <p className="muted">Sau khi đổi thành công, bạn sẽ đăng nhập lại bằng mật khẩu mới.</p>
      <form className="account-form" onSubmit={submit}>
        <fieldset disabled={busy}>
          <label>Mật khẩu hiện tại<input name="currentPassword" type="password" autoComplete="current-password" required maxLength={72} /></label>
          <label>Mật khẩu mới<input name="newPassword" type="password" autoComplete="new-password" required minLength={12} maxLength={72} aria-describedby="new-password-help" /></label>
          <small id="new-password-help">Ít nhất 12 ký tự, tối đa 72 byte.</small>
          <label>Nhập lại mật khẩu mới<input name="confirmPassword" type="password" autoComplete="new-password" required maxLength={72} /></label>
        </fieldset>
        {error && <p className="error" role="alert">{error}</p>}
        <div className="form-actions"><button className="primary" disabled={busy}><Icon name="shield" />{busy ? 'Đang đổi…' : 'Đổi mật khẩu'}</button></div>
      </form>
    </section>
  );
}

export function MyAccountPage({ request, profile, onUpdated, onPasswordChanged }) {
  return (
    <>
      <PageHeading title="Tài khoản của tôi" eyebrow="CÁ NHÂN" description="Cập nhật thông tin hiển thị và quản lý mật khẩu đăng nhập của bạn." />
      <div className="account-grid">
        <ProfileForm request={request} profile={profile} onUpdated={onUpdated} />
        <PasswordForm request={request} onChanged={onPasswordChanged} />
      </div>
    </>
  );
}
