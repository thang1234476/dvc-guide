import { Icon } from './ui.jsx';
import { useId } from 'react';
import { asList, moveItem, updateItem } from './procedureContent.js';

export function ContentField({ label, value, onChange, multiline = false, type = 'text', className = '', ...props }) {
  const id = useId();
  const update = event => onChange(type === 'number' ? event.target.value === '' ? null : Number(event.target.value) : event.target.value);
  return <div className={`form-field ${className}`}><label htmlFor={id}>{label}</label>{multiline
    ? <textarea id={id} value={value ?? ''} onChange={update} maxLength={16000} {...props} />
    : <input id={id} type={type} value={value ?? ''} onChange={update} {...props} />}</div>;
}

export function ContentList({ title, noun, value, onChange, create, render, getTitle, description }) {
  const items = asList(value);
  return <div className="content-list">
    <div className="content-list-heading"><div><h4>{title}</h4>{description && <p className="muted">{description}</p>}</div><span className="count-badge">{items.length} mục</span></div>
    {!items.length && <p className="content-list-empty">Chưa có {noun}. Bấm nút bên dưới để thêm.</p>}
    {items.map((item, index) => <details className="content-item" key={index} open={items.length <= 2 || index === items.length - 1}>
      <summary><span className="content-item-number">{index + 1}</span><span className="content-item-title" title={getTitle?.(item)}>{getTitle?.(item) || `${noun.charAt(0).toUpperCase() + noun.slice(1)} ${index + 1}`}</span><Icon name="right" /></summary>
      <div className="content-item-body">
        <div className="content-item-actions">
          <button type="button" className="button-small" disabled={index === 0} onClick={() => onChange(moveItem(items, index, -1))} aria-label={`Đưa ${noun} ${index + 1} lên`}>↑ Đưa lên</button>
          <button type="button" className="button-small" disabled={index + 1 === items.length} onClick={() => onChange(moveItem(items, index, 1))} aria-label={`Đưa ${noun} ${index + 1} xuống`}>↓ Đưa xuống</button>
          <button type="button" className="button-small danger" onClick={() => onChange(items.filter((_, i) => i !== index))} aria-label={`Bỏ ${noun} ${index + 1}`}>Bỏ mục</button>
        </div>
        {render(item, updated => onChange(updateItem(items, index, updated)), index)}
      </div>
    </details>)}
    <button type="button" className="button-small" onClick={() => onChange([...items, create()])}><Icon name="plus" />Thêm {noun}</button>
  </div>;
}

export function SubmissionFields({ value, onChange }) {
  const channels = { truc_tuyen: 'Trực tuyến', truc_tiep: 'Trực tiếp', buu_chinh: 'Bưu chính', khac: 'Khác' };
  return <ContentList title="Hình thức nộp, thời hạn và phí" noun="cách nộp" value={value} onChange={onChange}
    description="Mỗi cách nộp có thời hạn, các khoản phí và mô tả riêng. Giữ nguyên đơn vị chưa rõ như OTHER khi chưa xác minh."
    create={() => ({ hinh_thuc: 'truc_tiep', hinh_thuc_goc: '', thoi_han: { so: null, don_vi: null, goc: '' }, le_phi: [], mo_ta: '' })}
    getTitle={item => channels[item.hinh_thuc] ?? item.hinh_thuc} render={(item, change) => {
      const set = (key, val) => change({ ...item, [key]: val });
      const duration = item.thoi_han ?? {};
      return <>
        <div className="form-grid">
          <label>Hình thức nộp<select value={item.hinh_thuc ?? ''} onChange={e => set('hinh_thuc', e.target.value)}>
            {!Object.hasOwn(channels, item.hinh_thuc) && <option value={item.hinh_thuc ?? ''}>{item.hinh_thuc || 'Chưa xác định'}</option>}
            {Object.entries(channels).map(([code, name]) => <option key={code} value={code}>{name}</option>)}
          </select></label>
          <ContentField label="Hình thức theo nguồn" value={item.hinh_thuc_goc} onChange={v => set('hinh_thuc_goc', v)} maxLength={255} placeholder="Ví dụ: ONLINE, DIRECT…" />
          <ContentField label="Thời hạn — số" type="number" min="0" max="99999.9" step="0.1" value={duration.so} onChange={v => set('thoi_han', { ...duration, so: v })} />
          <ContentField label="Thời hạn — đơn vị" value={duration.don_vi} onChange={v => set('thoi_han', { ...duration, don_vi: v || null })} maxLength={50} placeholder="Ngày, ngày làm việc, giờ, khac…" />
          <ContentField label="Thời gian giải quyết nguyên văn" multiline className="full" value={duration.goc} onChange={v => set('thoi_han', { ...duration, goc: v })} />
          <ContentField label="Mô tả cách thức" multiline className="full" value={item.mo_ta} onChange={v => set('mo_ta', v)} />
        </div>
        <ContentList title="Phí, lệ phí" noun="khoản phí" value={item.le_phi} onChange={v => set('le_phi', v)}
          create={() => ({ so_tien: null, tien_te: null, mien_phi: false, ghi_chu: '' })} getTitle={fee => fee.mien_phi ? 'Miễn phí — xem ghi chú' : fee.so_tien == null ? 'Chưa rõ mức phí' : `${fee.so_tien} ${fee.tien_te ?? ''}`}
          render={(fee, changeFee) => <div className="form-grid">
            <ContentField label="Số tiền" type="number" min="0" step="0.01" max="9999999999999.99" value={fee.so_tien} onChange={v => changeFee({ ...fee, so_tien: v })} />
            <ContentField label="Tiền tệ" value={fee.tien_te} onChange={v => changeFee({ ...fee, tien_te: v || null })} maxLength={50} placeholder="VND, USD…" />
            <label className="checkbox-field full"><input type="checkbox" checked={fee.mien_phi === true} onChange={e => changeFee({ ...fee, mien_phi: e.target.checked })} />Được ghi nhận là miễn phí</label>
            <ContentField label="Ghi chú phí, lệ phí" multiline className="full" value={fee.ghi_chu} onChange={v => changeFee({ ...fee, ghi_chu: v })} />
          </div>} />
      </>;
    }} />;
}

export function DocumentFields({ value, onChange }) {
  return <ContentList title="Thành phần hồ sơ" noun="giấy tờ" value={value} onChange={onChange}
    description="Giữ đúng nhóm và trường hợp của file nguồn, kể cả các mục Lưu ý. Mỗi giấy tờ có thể gắn nhiều biểu mẫu."
    create={() => ({ nhom: 'nop', truong_hop: '', ten: '', so_ban_chinh: null, so_ban_sao: null, mau_don: [] })}
    getTitle={item => item.ten} render={(item, change) => {
      const set = (key, val) => change({ ...item, [key]: val });
      return <>
        <div className="form-grid">
          <ContentField label="Tên / nội dung giấy tờ" multiline required className="full" value={item.ten} onChange={v => set('ten', v)} />
          <ContentField label="Nhóm hồ sơ theo JSON" value={item.nhom} onChange={v => set('nhom', v)} maxLength={255} placeholder="nop, xuat_trinh…" />
          <ContentField label="Trường hợp / tiêu đề nhóm theo nguồn" value={item.truong_hop} onChange={v => set('truong_hop', v)} placeholder="Giấy tờ phải nộp:, Giấy tờ phải xuất trình:, Lưu ý:…" />
          <ContentField label="Số bản chính" type="number" min="0" max="32767" step="1" value={item.so_ban_chinh} onChange={v => set('so_ban_chinh', v)} />
          <ContentField label="Số bản sao" type="number" min="0" max="32767" step="1" value={item.so_ban_sao} onChange={v => set('so_ban_sao', v)} />
        </div>
        <ContentList title="Mẫu đơn, tờ khai (link Drive)" noun="biểu mẫu" value={item.mau_don} onChange={v => set('mau_don', v)}
          create={() => ({ ten: '', file_id: '', url: '', loi_tai: null })} getTitle={form => form.ten}
          render={(form, changeForm) => <div className="form-grid">
            <ContentField label="Tên biểu mẫu" required value={form.ten} onChange={v => changeForm({ ...form, ten: v })} maxLength={500} />
            <ContentField label="ID file nguồn" value={form.file_id} onChange={v => changeForm({ ...form, file_id: v })} maxLength={50} />
            <ContentField label="Link tải biểu mẫu" className="full" type="url" value={form.url} onChange={v => changeForm({ ...form, url: v })} maxLength={1000} placeholder="https://drive.google.com/…" />
            <ContentField label="Ghi nhận lỗi tải (nếu có)" className="full" value={form.loi_tai} onChange={v => changeForm({ ...form, loi_tai: v || null })} />
          </div>} />
      </>;
    }} />;
}
