import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/procedure_enums.dart';

part 'procedure_models.freezed.dart';
part 'procedure_models.g.dart';

@freezed
class LinhVuc with _$LinhVuc {
  const factory LinhVuc({
    required int id,
    String? ma,
    required String ten,
  }) = _LinhVuc;

  factory LinhVuc.fromJson(Map<String, dynamic> json) => _$LinhVucFromJson(json);
}

@freezed
class CoQuan with _$CoQuan {
  const factory CoQuan({
    required int id,
    String? ma,
    required String ten,
    required CapCoQuan cap,
    @JsonKey(name: 'dia_chi') String? diaChi,
    @JsonKey(name: 'dia_phuong_id') int? diaPhuongId,
    @JsonKey(name: 'vi_do') double? viDo,
    @JsonKey(name: 'kinh_do') double? kinhDo,
    @JsonKey(name: 'so_dien_thoai') String? soDienThoai,
    String? email,
    String? website,
    @JsonKey(name: 'gio_lam_viec') String? gioLamViec,
    @JsonKey(name: 'gio_phat_so') String? gioPhatSo,
    @Default(NguonDiaChi.duLieuGoc) @JsonKey(name: 'nguon_dia_chi') NguonDiaChi nguonDiaChi,
    @Default(false) @JsonKey(name: 'da_kiem_chung') bool daKiemChung,
    @JsonKey(name: 'kiem_chung_luc') String? kiemChungLuc,
  }) = _CoQuan;

  factory CoQuan.fromJson(Map<String, dynamic> json) => _$CoQuanFromJson(json);
}

@freezed
class ThuTucKetQua with _$ThuTucKetQua {
  const factory ThuTucKetQua({
    required int id,
    required String ten,
    @Default(1) @JsonKey(name: 'thu_tu') int thuTu,
  }) = _ThuTucKetQua;

  factory ThuTucKetQua.fromJson(Map<String, dynamic> json) => _$ThuTucKetQuaFromJson(json);
}

@freezed
class ThuTucCoQuanDetail with _$ThuTucCoQuanDetail {
  const factory ThuTucCoQuanDetail({
    @JsonKey(name: 'co_quan') required CoQuan coQuan,
    @JsonKey(name: 'ghi_chu') String? ghiChu,
  }) = _ThuTucCoQuanDetail;

  factory ThuTucCoQuanDetail.fromJson(Map<String, dynamic> json) => _$ThuTucCoQuanDetailFromJson(json);
}

@freezed
class TruongHop with _$TruongHop {
  const factory TruongHop({
    required int id,
    required String ten,
    @JsonKey(name: 'dieu_kien') String? dieuKien,
    @JsonKey(name: 'cau_hoi_phan_loai') String? cauHoiPhanLoai,
    @Default(0) @JsonKey(name: 'thu_tu') int thuTu,
  }) = _TruongHop;

  factory TruongHop.fromJson(Map<String, dynamic> json) => _$TruongHopFromJson(json);
}

@freezed
class BieuMau with _$BieuMau {
  const factory BieuMau({
    required int id,
    required String ten,
    @JsonKey(name: 'file_docx_url') String? fileDocxUrl,
    @JsonKey(name: 'file_pdf_url') String? filePdfUrl,
  }) = _BieuMau;

  factory BieuMau.fromJson(Map<String, dynamic> json) => _$BieuMauFromJson(json);
}

@freezed
class ThanhPhanHoSo with _$ThanhPhanHoSo {
  const factory ThanhPhanHoSo({
    required int id,
    @JsonKey(name: 'truong_hop_id') int? truongHopId,
    String? nhom,
    @JsonKey(name: 'ten_giay_to') required String tenGiayTo,
    @JsonKey(name: 'truong_hop_goc') String? truongHopGoc,
    @JsonKey(name: 'so_luong_ban_chinh') int? soLuongBanChinh,
    @JsonKey(name: 'so_luong_ban_sao') int? soLuongBanSao,
    @JsonKey(name: 'bat_buoc') bool? batBuoc,
    @JsonKey(name: 'bieu_mau') BieuMau? bieuMau,
    @JsonKey(name: 'ghi_chu') String? ghiChu,
    @Default(0) @JsonKey(name: 'thu_tu') int thuTu,
  }) = _ThanhPhanHoSo;

  factory ThanhPhanHoSo.fromJson(Map<String, dynamic> json) => _$ThanhPhanHoSoFromJson(json);
}

@freezed
class BuocThucHien with _$BuocThucHien {
  const factory BuocThucHien({
    required int id,
    @Default(HinhThucBuoc.chung) @JsonKey(name: 'hinh_thuc') HinhThucBuoc hinhThuc,
    @JsonKey(name: 'thu_tu') required int thuTu,
    @JsonKey(name: 'tieu_de') String? tieuDe,
    @JsonKey(name: 'mo_ta') String? moTa,
    @JsonKey(name: 'anh_huong_dan_url') String? anhHuongDanUrl,
  }) = _BuocThucHien;

  factory BuocThucHien.fromJson(Map<String, dynamic> json) => _$BuocThucHienFromJson(json);
}

@freezed
class LePhi with _$LePhi {
  const factory LePhi({
    required int id,
    @Default(false) @JsonKey(name: 'mien_phi') bool mienPhi,
    @JsonKey(name: 'so_tien') double? soTien,
    @JsonKey(name: 'tien_te') String? tienTe,
    @JsonKey(name: 'ghi_chu') String? ghiChu,
    @Default(1) @JsonKey(name: 'thu_tu') int thuTu,
  }) = _LePhi;

  factory LePhi.fromJson(Map<String, dynamic> json) => _$LePhiFromJson(json);
}

@freezed
class HinhThucNopChiTiet with _$HinhThucNopChiTiet {
  const factory HinhThucNopChiTiet({
    required int id,
    @JsonKey(name: 'hinh_thuc') required HinhThucNop hinhThuc,
    @JsonKey(name: 'hinh_thuc_goc') String? hinhThucGoc,
    @JsonKey(name: 'thoi_han_so') double? thoiHanSo,
    @JsonKey(name: 'thoi_han_don_vi') String? thoiHanDonVi,
    @JsonKey(name: 'thoi_han_goc') String? thoiHanGoc,
    @JsonKey(name: 'link_nop') String? linkNop,
    @JsonKey(name: 'dia_chi_nop') String? diaChiNop,
    @JsonKey(name: 'gio_tiep_nhan') String? gioTiepNhan,
    @Default([]) @JsonKey(name: 'le_phi') List<LePhi> lePhi,
  }) = _HinhThucNopChiTiet;

  factory HinhThucNopChiTiet.fromJson(Map<String, dynamic> json) => _$HinhThucNopChiTietFromJson(json);
}

@freezed
class VanBanPhapLyChiTiet with _$VanBanPhapLyChiTiet {
  const factory VanBanPhapLyChiTiet({
    required int id,
    @JsonKey(name: 'so_hieu') required String soHieu,
    required String ten,
    @Default(LoaiVanBan.khac) LoaiVanBan loai,
    @JsonKey(name: 'co_quan_ban_hanh') String? coQuanBanHanh,
    @JsonKey(name: 'ngay_ban_hanh') String? ngayBanHanh,
    @JsonKey(name: 'ngay_hieu_luc') String? ngayHieuLuc,
    @JsonKey(name: 'ngay_het_hieu_luc') String? ngayHetHieuLuc,
    @Default(TrangThaiHieuLuc.chuaXacMinh)
    @JsonKey(name: 'trang_thai_hieu_luc')
    TrangThaiHieuLuc trangThaiHieuLuc,
    String? url,
    @Default('') @JsonKey(name: 'dieu_khoan') String dieuKhoan,
  }) = _VanBanPhapLyChiTiet;

  factory VanBanPhapLyChiTiet.fromJson(Map<String, dynamic> json) => _$VanBanPhapLyChiTietFromJson(json);
}

@freezed
class ThuTucSummary with _$ThuTucSummary {
  const factory ThuTucSummary({
    required int id,
    @JsonKey(name: 'ma_thu_tuc') required String maThuTuc,
    required String ten,
    @JsonKey(name: 'cap_thuc_hien') CapCoQuan? capThucHien,
    @Default([]) @JsonKey(name: 'linh_vuc') List<LinhVuc> linhVuc,
  }) = _ThuTucSummary;

  factory ThuTucSummary.fromJson(Map<String, dynamic> json) => _$ThuTucSummaryFromJson(json);
}

@freezed
class ThuTucDetail with _$ThuTucDetail {
  const factory ThuTucDetail({
    required int id,
    @JsonKey(name: 'ma_thu_tuc') required String maThuTuc,
    required String ten,
    @JsonKey(name: 'cap_thuc_hien') CapCoQuan? capThucHien,
    @JsonKey(name: 'co_quan_thuc_hien_goc') String? coQuanThucHienGoc,
    @JsonKey(name: 'doi_tuong') String? doiTuong,
    @JsonKey(name: 'dieu_kien') String? dieuKien,
    @JsonKey(name: 'link_dvc') String? linkDvc,
    @Default([]) @JsonKey(name: 'linh_vuc') List<LinhVuc> linhVuc,
    @Default([]) @JsonKey(name: 'ket_qua') List<ThuTucKetQua> ketQua,
    @Default([]) @JsonKey(name: 'co_quan') List<ThuTucCoQuanDetail> coQuan,
    @Default([]) @JsonKey(name: 'truong_hop') List<TruongHop> truongHop,
    @Default([]) @JsonKey(name: 'thanh_phan_ho_so') List<ThanhPhanHoSo> thanhPhanHoSo,
    @Default([]) @JsonKey(name: 'buoc_thuc_hien') List<BuocThucHien> buocThucHien,
    @Default([]) @JsonKey(name: 'hinh_thuc_nop') List<HinhThucNopChiTiet> hinhThucNop,
    @Default([]) @JsonKey(name: 'van_ban') List<VanBanPhapLyChiTiet> vanBan,
  }) = _ThuTucDetail;

  factory ThuTucDetail.fromJson(Map<String, dynamic> json) => _$ThuTucDetailFromJson(json);
}
