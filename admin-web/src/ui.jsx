export function Icon({ name, className = '', ...props }) {
  const paths = {
    document: <><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9Z" /><path d="M14 3v6h6M8 13h8M8 17h5" /></>,
    upload: <><path d="M12 16V3m-4 4 4-4 4 4M4 15v4a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-4" /></>,
    download: <><path d="M12 3v13m-4-4 4 4 4-4M4 17v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3" /></>,
    refresh: <><path d="M20 7v5h-5M4 17v-5h5" /><path d="M6.1 6a8 8 0 0 1 13.6 5M4.3 13a8 8 0 0 0 13.6 5" /></>,
    history: <><path d="M3 4v5h5M3.6 9a9 9 0 1 1-.1 6" /><path d="M12 7v5l3 2" /></>,
    users: <><circle cx="9" cy="8" r="3" /><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6m2 4a5 5 0 0 1 3 4v2" /></>,
    user: <><circle cx="12" cy="8" r="3.5" /><path d="M5 21v-3a7 7 0 0 1 14 0v3" /></>,
    logout: <><path d="M9 4H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h4M14 8l4 4-4 4M8 12h13" /></>,
    menu: <path d="M4 6h16M4 12h16M4 18h16" />,
    close: <path d="m6 6 12 12M18 6 6 18" />,
    search: <><circle cx="10.5" cy="10.5" r="6.5" /><path d="m16 16 5 5" /></>,
    plus: <path d="M12 5v14M5 12h14" />,
    right: <path d="m9 5 7 7-7 7" />,
    left: <path d="m15 5-7 7 7 7" />,
    filter: <><path d="M4 6h16M7 12h10M10 18h4" /><circle cx="8" cy="6" r="2" fill="currentColor" stroke="none" /><circle cx="15" cy="12" r="2" fill="currentColor" stroke="none" /></>,
    shield: <><path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6Z" /><path d="m8 12 3 3 5-6" /></>,
    check: <path d="m5 12 4 4L19 6" />,
    edit: <><path d="m15 5 4 4M4 20l5-1L20 8a3 3 0 0 0-4-4L5 15Z" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  };
  return <svg className={`icon ${className}`} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false" {...props}>{paths[name] ?? paths.document}</svg>;
}

export function PageHeading({ title, description, eyebrow, children }) {
  return <div className="section-heading page-heading">
    <div>{eyebrow && <p className="eyebrow">{eyebrow}</p>}<h1>{title}</h1>
      {description && <p className="page-description">{description}</p>}</div>
    {children && <div className="heading-actions">{children}</div>}
  </div>;
}

export function PanelHeading({ title, description, icon, children }) {
  return <div className="panel-heading">
    <div className="panel-heading-main">{icon && <span className="panel-icon"><Icon name={icon} /></span>}
      <div><h2>{title}</h2>{description && <p className="muted">{description}</p>}</div>
    </div>{children}
  </div>;
}

export function FormSection({ number, title, description, id, children }) {
  return <section className="form-section" aria-labelledby={id}>
    <div className="form-section-heading"><span className="section-number" aria-hidden="true">{number}</span>
      <div><h3 id={id}>{title}</h3>{description && <p>{description}</p>}</div>
    </div>{children}
  </section>;
}

export function TableScroll({ children, label = 'Bảng dữ liệu' }) {
  return <div className="table-container"><p className="table-hint">Kéo bảng sang ngang để xem đầy đủ thông tin.</p>
    <div className="table-wrap" tabIndex={0} role="region" aria-label={label}>{children}</div>
  </div>;
}

export function Pagination({ data, onPage, disabled = false }) {
  if (!data || !data.totalElements) return null;
  const start = data.page * data.size + 1;
  const end = start + data.items.length - 1;
  return <div className="pagination">
    <span className="pagination-summary">{data.items.length ? <>Hiển thị <strong>{start}–{end}</strong> trên <strong>{data.totalElements}</strong> kết quả</> : 'Không có kết quả ở trang này'}</span>
    <div className="pagination-controls"><span>Trang {data.page + 1}/{data.totalPages}</span>
      <button disabled={disabled || data.page === 0} onClick={() => onPage(data.page - 1)} aria-label="Trang trước"><Icon name="left" /></button>
      <button disabled={disabled || data.page + 1 >= data.totalPages} onClick={() => onPage(data.page + 1)} aria-label="Trang sau"><Icon name="right" /></button>
    </div>
  </div>;
}

export function EmptyState({ title, description, icon = 'document' }) {
  return <div className="empty-state"><span className="empty-icon"><Icon name={icon} /></span>
    <h3>{title}</h3>{description && <p className="muted">{description}</p>}</div>;
}
