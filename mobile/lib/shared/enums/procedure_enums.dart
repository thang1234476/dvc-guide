import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_strings.dart';

/// Administrative authority level (cap / cap_thuc_hien)
enum CapCoQuan {
  @JsonValue('trung_uong')
  trungUong,
  @JsonValue('tinh')
  tinh,
  @JsonValue('huyen')
  huyen,
  @JsonValue('xa')
  xa;

  String get displayName {
    switch (this) {
      case CapCoQuan.trungUong:
        return 'Trung ương';
      case CapCoQuan.tinh:
        return 'Cấp tỉnh';
      case CapCoQuan.huyen:
        return 'Cấp huyện';
      case CapCoQuan.xa:
        return 'Cấp xã';
    }
  }

  String toJson() => switch (this) {
        CapCoQuan.trungUong => 'trung_uong',
        CapCoQuan.tinh => 'tinh',
        CapCoQuan.huyen => 'huyen',
        CapCoQuan.xa => 'xa',
      };

  static CapCoQuan fromJson(String json) => switch (json) {
        'trung_uong' => CapCoQuan.trungUong,
        'tinh' => CapCoQuan.tinh,
        'huyen' => CapCoQuan.huyen,
        'xa' => CapCoQuan.xa,
        _ => throw ArgumentError('Unknown CapCoQuan: $json'),
      };
}

/// Procedure status (trang_thai)
enum TrangThaiThuTuc {
  @JsonValue('nhap')
  nhap,
  @JsonValue('dang_dung')
  dangDung,
  @JsonValue('ngung')
  ngung;

  String toJson() => switch (this) {
        TrangThaiThuTuc.nhap => 'nhap',
        TrangThaiThuTuc.dangDung => 'dang_dung',
        TrangThaiThuTuc.ngung => 'ngung',
      };

  static TrangThaiThuTuc fromJson(String json) => switch (json) {
        'nhap' => TrangThaiThuTuc.nhap,
        'dang_dung' => TrangThaiThuTuc.dangDung,
        'ngung' => TrangThaiThuTuc.ngung,
        _ => throw ArgumentError('Unknown TrangThaiThuTuc: $json'),
      };
}

/// Step execution method (buoc_thuc_hien.hinh_thuc)
enum HinhThucBuoc {
  @JsonValue('chung')
  chung,
  @JsonValue('truc_tuyen')
  trucTuyen,
  @JsonValue('truc_tiep')
  trucTiep,
  @JsonValue('buu_chinh')
  buuChinh,
  @JsonValue('khac')
  khac;

  String get displayName {
    switch (this) {
      case HinhThucBuoc.chung:
        return 'Chung';
      case HinhThucBuoc.trucTuyen:
        return 'Trực tuyến';
      case HinhThucBuoc.trucTiep:
        return 'Trực tiếp';
      case HinhThucBuoc.buuChinh:
        return 'Bưu chính';
      case HinhThucBuoc.khac:
        return 'Khác';
    }
  }

  String toJson() => switch (this) {
        HinhThucBuoc.chung => 'chung',
        HinhThucBuoc.trucTuyen => 'truc_tuyen',
        HinhThucBuoc.trucTiep => 'truc_tiep',
        HinhThucBuoc.buuChinh => 'buu_chinh',
        HinhThucBuoc.khac => 'khac',
      };

  static HinhThucBuoc fromJson(String json) => switch (json) {
        'chung' => HinhThucBuoc.chung,
        'truc_tuyen' => HinhThucBuoc.trucTuyen,
        'truc_tiep' => HinhThucBuoc.trucTiep,
        'buu_chinh' => HinhThucBuoc.buuChinh,
        'khac' => HinhThucBuoc.khac,
        _ => throw ArgumentError('Unknown HinhThucBuoc: $json'),
      };
}

/// Submission method (hinh_thuc_nop_chi_tiet.hinh_thuc)
enum HinhThucNop {
  @JsonValue('truc_tuyen')
  trucTuyen,
  @JsonValue('truc_tiep')
  trucTiep,
  @JsonValue('buu_chinh')
  buuChinh,
  @JsonValue('khac')
  khac;

  String get displayName {
    switch (this) {
      case HinhThucNop.trucTuyen:
        return 'Trực tuyến';
      case HinhThucNop.trucTiep:
        return 'Trực tiếp';
      case HinhThucNop.buuChinh:
        return 'Bưu chính';
      case HinhThucNop.khac:
        return 'Khác';
    }
  }

  String toJson() => switch (this) {
        HinhThucNop.trucTuyen => 'truc_tuyen',
        HinhThucNop.trucTiep => 'truc_tiep',
        HinhThucNop.buuChinh => 'buu_chinh',
        HinhThucNop.khac => 'khac',
      };

  static HinhThucNop fromJson(String json) => switch (json) {
        'truc_tuyen' => HinhThucNop.trucTuyen,
        'truc_tiep' => HinhThucNop.trucTiep,
        'buu_chinh' => HinhThucNop.buuChinh,
        'khac' => HinhThucNop.khac,
        _ => throw ArgumentError('Unknown HinhThucNop: $json'),
      };
}

/// Legal document type (van_ban_phap_ly.loai)
enum LoaiVanBan {
  @JsonValue('luat')
  luat,
  @JsonValue('nghi_dinh')
  nghiDinh,
  @JsonValue('thong_tu')
  thongTu,
  @JsonValue('quyet_dinh')
  quyetDinh,
  @JsonValue('nghi_quyet')
  nghiQuyet,
  @JsonValue('khac')
  khac;

  String get displayName {
    switch (this) {
      case LoaiVanBan.luat:
        return 'Luật';
      case LoaiVanBan.nghiDinh:
        return 'Nghị định';
      case LoaiVanBan.thongTu:
        return 'Thông tư';
      case LoaiVanBan.quyetDinh:
        return 'Quyết định';
      case LoaiVanBan.nghiQuyet:
        return 'Nghị quyết';
      case LoaiVanBan.khac:
        return 'Văn bản khác';
    }
  }

  String toJson() => switch (this) {
        LoaiVanBan.luat => 'luat',
        LoaiVanBan.nghiDinh => 'nghi_dinh',
        LoaiVanBan.thongTu => 'thong_tu',
        LoaiVanBan.quyetDinh => 'quyet_dinh',
        LoaiVanBan.nghiQuyet => 'nghi_quyet',
        LoaiVanBan.khac => 'khac',
      };

  static LoaiVanBan fromJson(String json) => switch (json) {
        'luat' => LoaiVanBan.luat,
        'nghi_dinh' => LoaiVanBan.nghiDinh,
        'thong_tu' => LoaiVanBan.thongTu,
        'quyet_dinh' => LoaiVanBan.quyetDinh,
        'nghi_quyet' => LoaiVanBan.nghiQuyet,
        'khac' => LoaiVanBan.khac,
        _ => throw ArgumentError('Unknown LoaiVanBan: $json'),
      };
}

/// Legal document validity status (van_ban_phap_ly.trang_thai_hieu_luc)
enum TrangThaiHieuLuc {
  @JsonValue('chua_xac_minh')
  chuaXacMinh,
  @JsonValue('con_hieu_luc')
  conHieuLuc,
  @JsonValue('het_hieu_luc')
  hetHieuLuc;

  String get displayName {
    switch (this) {
      case TrangThaiHieuLuc.chuaXacMinh:
        return 'Chưa xác minh hiệu lực';
      case TrangThaiHieuLuc.conHieuLuc:
        return 'Còn hiệu lực';
      case TrangThaiHieuLuc.hetHieuLuc:
        return 'Hết hiệu lực';
    }
  }

  String toJson() => switch (this) {
        TrangThaiHieuLuc.chuaXacMinh => 'chua_xac_minh',
        TrangThaiHieuLuc.conHieuLuc => 'con_hieu_luc',
        TrangThaiHieuLuc.hetHieuLuc => 'het_hieu_luc',
      };

  static TrangThaiHieuLuc fromJson(String json) => switch (json) {
        'chua_xac_minh' => TrangThaiHieuLuc.chuaXacMinh,
        'con_hieu_luc' => TrangThaiHieuLuc.conHieuLuc,
        'het_hieu_luc' => TrangThaiHieuLuc.hetHieuLuc,
        _ => throw ArgumentError('Unknown TrangThaiHieuLuc: $json'),
      };
}

/// Chat message role (tin_nhan.vai_tro)
enum VaiTroTinNhan {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('tool')
  tool;

  String toJson() => switch (this) {
        VaiTroTinNhan.user => 'user',
        VaiTroTinNhan.assistant => 'assistant',
        VaiTroTinNhan.tool => 'tool',
      };

  static VaiTroTinNhan fromJson(String json) => switch (json) {
        'user' => VaiTroTinNhan.user,
        'assistant' => VaiTroTinNhan.assistant,
        'tool' => VaiTroTinNhan.tool,
        _ => throw ArgumentError('Unknown VaiTroTinNhan: $json'),
      };
}

/// AI answer tracking status (tin_nhan.trang_thai_tra_loi)
enum TrangThaiTraLoi {
  @JsonValue('answered')
  answered,
  @JsonValue('gate')
  gate,
  @JsonValue('model')
  model,
  @JsonValue('guard')
  guard;

  String toJson() => switch (this) {
        TrangThaiTraLoi.answered => 'answered',
        TrangThaiTraLoi.gate => 'gate',
        TrangThaiTraLoi.model => 'model',
        TrangThaiTraLoi.guard => 'guard',
      };

  static TrangThaiTraLoi fromJson(String json) => switch (json) {
        'answered' => TrangThaiTraLoi.answered,
        'gate' => TrangThaiTraLoi.gate,
        'model' => TrangThaiTraLoi.model,
        'guard' => TrangThaiTraLoi.guard,
        _ => throw ArgumentError('Unknown TrangThaiTraLoi: $json'),
      };
}

/// Case tracking status (ho_so_cua_toi.trang_thai)
enum TrangThaiHoSo {
  @JsonValue('dang_chuan_bi')
  dangChuanBi,
  @JsonValue('da_nop')
  daNop,
  @JsonValue('dang_xu_ly')
  dangXuLy,
  @JsonValue('can_bo_sung')
  canBoSung,
  @JsonValue('da_nhan_ket_qua')
  daNhanKetQua;

  String get displayName => switch (this) {
        TrangThaiHoSo.dangChuanBi => AppStrings.statusCasePreparing,
        TrangThaiHoSo.daNop => AppStrings.statusCaseSubmitted,
        TrangThaiHoSo.dangXuLy => AppStrings.statusCaseProcessing,
        TrangThaiHoSo.canBoSung => AppStrings.statusCaseNeedSupplement,
        TrangThaiHoSo.daNhanKetQua => AppStrings.statusCaseReceivedResult,
      };

  String toJson() => switch (this) {
        TrangThaiHoSo.dangChuanBi => 'dang_chuan_bi',
        TrangThaiHoSo.daNop => 'da_nop',
        TrangThaiHoSo.dangXuLy => 'dang_xu_ly',
        TrangThaiHoSo.canBoSung => 'can_bo_sung',
        TrangThaiHoSo.daNhanKetQua => 'da_nhan_ket_qua',
      };

  static TrangThaiHoSo fromJson(String json) => switch (json) {
        'dang_chuan_bi' => TrangThaiHoSo.dangChuanBi,
        'da_nop' => TrangThaiHoSo.daNop,
        'dang_xu_ly' => TrangThaiHoSo.dangXuLy,
        'can_bo_sung' => TrangThaiHoSo.canBoSung,
        'da_nhan_ket_qua' => TrangThaiHoSo.daNhanKetQua,
        _ => throw ArgumentError('Unknown TrangThaiHoSo: $json'),
      };
}

/// Checklist paper status (ho_so_checklist.trang_thai)
enum TrangThaiGiayTo {
  @JsonValue('da_co')
  daCo,
  @JsonValue('chua_co')
  chuaCo,
  @JsonValue('chua_ro')
  chuaRo;

  String get displayName => switch (this) {
        TrangThaiGiayTo.daCo => AppStrings.statusPaperReady,
        TrangThaiGiayTo.chuaCo => AppStrings.statusPaperMissing,
        TrangThaiGiayTo.chuaRo => AppStrings.statusPaperUnknown,
      };

  String toJson() => switch (this) {
        TrangThaiGiayTo.daCo => 'da_co',
        TrangThaiGiayTo.chuaCo => 'chua_co',
        TrangThaiGiayTo.chuaRo => 'chua_ro',
      };

  static TrangThaiGiayTo fromJson(String json) => switch (json) {
        'da_co' => TrangThaiGiayTo.daCo,
        'chua_co' => TrangThaiGiayTo.chuaCo,
        'chua_ro' => TrangThaiGiayTo.chuaRo,
        _ => throw ArgumentError('Unknown TrangThaiGiayTo: $json'),
      };
}

/// Agency address provenance (co_quan.nguon_dia_chi)
enum NguonDiaChi {
  @JsonValue('du_lieu_goc')
  duLieuGoc,
  @JsonValue('ai')
  ai,
  @JsonValue('quan_tri')
  quanTri;

  String get displayName => switch (this) {
        NguonDiaChi.duLieuGoc => AppStrings.addressSourceOriginal,
        NguonDiaChi.ai => AppStrings.addressSourceAi,
        NguonDiaChi.quanTri => AppStrings.addressSourceAdmin,
      };

  String toJson() => switch (this) {
        NguonDiaChi.duLieuGoc => 'du_lieu_goc',
        NguonDiaChi.ai => 'ai',
        NguonDiaChi.quanTri => 'quan_tri',
      };

  static NguonDiaChi fromJson(String json) => switch (json) {
        'du_lieu_goc' => NguonDiaChi.duLieuGoc,
        'ai' => NguonDiaChi.ai,
        'quan_tri' => NguonDiaChi.quanTri,
        _ => throw ArgumentError('Unknown NguonDiaChi: $json'),
      };
}

/// Feedback report type (gop_y.loai)
enum LoaiGopY {
  @JsonValue('gop_y')
  gopY,
  @JsonValue('bao_loi')
  baoLoi,
  @JsonValue('sai_dia_chi')
  saiDiaChi;

  String get displayName => switch (this) {
        LoaiGopY.gopY => AppStrings.feedbackTypeFeedback,
        LoaiGopY.baoLoi => AppStrings.feedbackTypeError,
        LoaiGopY.saiDiaChi => AppStrings.feedbackTypeWrongAddress,
      };

  String toJson() => switch (this) {
        LoaiGopY.gopY => 'gop_y',
        LoaiGopY.baoLoi => 'bao_loi',
        LoaiGopY.saiDiaChi => 'sai_dia_chi',
      };

  static LoaiGopY fromJson(String json) => switch (json) {
        'gop_y' => LoaiGopY.gopY,
        'bao_loi' => LoaiGopY.baoLoi,
        'sai_dia_chi' => LoaiGopY.saiDiaChi,
        _ => throw ArgumentError('Unknown LoaiGopY: $json'),
      };
}
