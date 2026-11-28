import React, { useCallback, useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Link, Navigate, NavLink, Outlet, Route, Routes, useLocation } from 'react-router';
import { api } from './api.js';
import { ProceduresPage } from './ProceduresPage.jsx';
import { AdminAccountsPage } from './AdminAccountsPage.jsx';
import { MyAccountPage } from './MyAccountPage.jsx';
import { ImportProceduresPage } from './ImportProceduresPage.jsx';
import { RagSourcesPage } from './RagSourcesPage.jsx';
import { ChangeLogsPage } from './ChangeLogsPage.jsx';
import { Icon } from './ui.jsx';
import './styles.css';

function Login({ onLogin, notice }) {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setBusy(true);
    setError('');
    try {
      const profile = await api('/admin/auth/login', {
        method: 'POST', body: { email: form.get('email').trim(), password: form.get('password') },
      });
      onLogin(profile);
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="login">
      <section className="panel" aria-labelledby="login-title">
        <div className="login-brand"><span className="brand-mark"><Icon name="document" /></span><p className="brand">DVC Guide</p></div>
        <p className="eyebrow">KHÔNG GIAN QUẢN TRỊ</p>
        <h1 id="login-title">Đăng nhập quản trị</h1>
        <p className="muted login-description">Đăng nhập để quản lý thủ tục, dữ liệu và tài khoản của hệ thống.</p>
        {notice && <p className="notice" role="status">{notice}</p>}
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

function RequireLogin({ profile }) {
  const location = useLocation();
  return profile ? <Outlet /> : <Navigate to="/login" replace
    state={{ from: location.pathname + location.search + location.hash }} />;
}

function Workspace({ profile, logout }) {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const menuButton = useRef(null);
  const location = useLocation();
  const sections = [
    { path: '/admin/procedures', name: 'Thủ tục', icon: 'document' },
    { path: '/admin/imports', name: 'Nhập dữ liệu', icon: 'upload' },
    { path: '/admin/ai-sources', name: 'Đồng bộ RAG', icon: 'refresh' },
    { path: '/admin/change-logs', name: 'Lịch sử thay đổi', icon: 'history' },
  ];
  const currentPage = [...sections, { path: '/admin/accounts', name: 'Tài khoản admin' }, { path: '/admin/me', name: 'Tài khoản của tôi' }]
    .find(section => location.pathname === section.path)?.name ?? 'Quản trị';
  useEffect(() => { setMenuOpen(false); window.scrollTo(0, 0); }, [location.pathname]);
  function closeMenuOnEscape(event) {
    if (event.key === 'Escape' && menuOpen) { setMenuOpen(false); menuButton.current?.focus(); }
  }

  async function signOut() {
    setBusy(true);
    setError('');
    try {
      await logout();
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <a className="skip-link" href="#workspace-content">Đến nội dung chính</a>
      <header className="app-header">
        <div className="shell topbar">
          <div className="brand-area">
            <button ref={menuButton} className="menu-toggle icon-button" aria-label={menuOpen ? 'Đóng menu' : 'Mở menu'} aria-expanded={menuOpen} aria-controls="workspace-navigation" onClick={() => setMenuOpen(value => !value)} onKeyDown={closeMenuOnEscape}><Icon name={menuOpen ? 'close' : 'menu'} /></button>
            <Link className="brand brand-link" to="/admin"><span className="brand-mark"><Icon name="document" /></span><span>DVC Guide<small>QUẢN TRỊ HỆ THỐNG</small></span></Link>
          </div>
          <div className="account">
            <NavLink className="account-link" to="/admin/me" aria-label="Tài khoản của tôi" title="Tài khoản của tôi">
              <Icon className="account-icon" name="user" />
              <span>{profile.displayName || profile.email}</span>
            </NavLink>
            <button className="logout-button" disabled={busy} onClick={signOut} aria-label={busy ? 'Đang đăng xuất…' : 'Đăng xuất'}><Icon name="logout" /><span>{busy ? 'Đang đăng xuất…' : 'Đăng xuất'}</span></button>
          </div>
        </div>
      </header>
      <div className="workspace-layout">
        <aside id="workspace-navigation" className={`navigation${menuOpen ? ' is-open' : ''}`} onKeyDown={closeMenuOnEscape}>
          <nav className="workspace-nav" aria-label="Chức năng quản trị">
            <p className="nav-group-title">NỘI DUNG & DỮ LIỆU</p>
            {sections.map(section => <NavLink key={section.path} to={section.path} onClick={() => setMenuOpen(false)}><Icon name={section.icon} /><span>{section.name}</span></NavLink>)}
            {profile.role === 'admin' && <><p className="nav-group-title nav-group-divider">QUẢN TRỊ</p><NavLink to="/admin/accounts" onClick={() => setMenuOpen(false)}><Icon name="users" /><span>Tài khoản admin</span></NavLink></>}
          </nav>
          <div className="sidebar-note"><Icon name="shield" /><p>Trung tâm quản trị<small>DVC Guide</small></p></div>
        </aside>
        <div className="workspace-body">
          <div className="breadcrumb"><span>Quản trị</span><Icon name="right" /><span aria-current="page">{currentPage}</span></div>
          {error && <div className="workspace-message"><p className="error" role="alert">{error}</p></div>}
          <main id="workspace-content" className="workspace" tabIndex={-1}><Outlet /></main>
        </div>
      </div>
    </>
  );
}

function MissingPage({ forbidden = false }) {
  return <section className="panel">
    <h1>{forbidden ? 'Bạn không có quyền truy cập' : 'Không tìm thấy trang'}</h1>
    <p>{forbidden ? 'Chỉ quản trị viên được xem và tạo tài khoản admin.' : 'Đường dẫn này không tồn tại.'}</p>
    <Link to="/admin/procedures">Về trang quản lý thủ tục</Link>
  </section>;
}

function App() {
  const [profile, setProfile] = useState(undefined);
  const [notice, setNotice] = useState('');
  const [initialError, setInitialError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const location = useLocation();

  useEffect(() => {
    const controller = new AbortController();
    setInitialError('');
    api('/admin/me', { signal: controller.signal }).then(setProfile).catch((failure) => {
      if (controller.signal.aborted) return;
      if (failure.status === 401) setProfile(null);
      else setInitialError(failure.message);
    });
    return () => controller.abort();
  }, [attempt]);

  const endSession = useCallback((message = '') => {
    setProfile(null);
    setNotice(message);
  }, []);
  const request = useCallback(async (path, options = {}) => {
    try {
      return await api(path, options);
    } catch (failure) {
      if (failure.status === 401) endSession('Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.');
      throw failure;
    }
  }, [endSession]);
  const logout = useCallback(async () => {
    await request('/admin/auth/logout', { method: 'POST' });
    endSession();
  }, [request, endSession]);
  const updateProfile = useCallback((updated) => {
    setProfile((previous) => previous?.id === updated.id ? updated : previous);
  }, []);

  if (profile === undefined) return <main className="login"><section className="panel">
    <p className="brand">DVC Guide</p>
    {initialError ? <>
      <p className="error" role="alert">Không thể kiểm tra phiên đăng nhập: {initialError}</p>
      <button onClick={() => setAttempt((previous) => previous + 1)}>Thử lại</button>
    </> : <p role="status">Đang kiểm tra phiên đăng nhập…</p>}
  </section></main>;

  const from = location.state?.from;
  const destination = typeof from === 'string' && /^\/admin(?:\/|$)/.test(from) ? from : '/admin/procedures';
  return <Routes>
    <Route path="/login" element={profile ? <Navigate to={destination} replace /> :
      <Login notice={notice} onLogin={(next) => { setNotice(''); setProfile(next); }} />} />
    <Route element={<RequireLogin profile={profile} />}>
      <Route path="/admin" element={<Workspace profile={profile} logout={logout} />}>
        <Route index element={<Navigate to="procedures" replace />} />
        <Route path="procedures" element={<ProceduresPage request={request} />} />
        <Route path="imports" element={<ImportProceduresPage request={request} />} />
        <Route path="ai-sources" element={<RagSourcesPage request={request} />} />
        <Route path="change-logs" element={<ChangeLogsPage request={request} />} />
        <Route path="accounts" element={profile?.role === 'admin' ? <AdminAccountsPage request={request} /> : <MissingPage forbidden />} />
        <Route path="me" element={<MyAccountPage request={request} profile={profile} onUpdated={updateProfile}
          onPasswordChanged={() => endSession('Đã đổi mật khẩu thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.')} />} />
        <Route path="*" element={<MissingPage />} />
      </Route>
    </Route>
    <Route path="/" element={<Navigate to="/admin" replace />} />
    <Route path="*" element={<main className="shell workspace"><MissingPage /></main>} />
  </Routes>;
}

createRoot(document.getElementById('root')).render(<BrowserRouter><App /></BrowserRouter>);
