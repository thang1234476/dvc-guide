import 'package:flutter_test/flutter_test.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

void main() {
  group('Procedure Enums JSON Serialization', () {
    test('CapCoQuan serialization matches schema', () {
      expect(CapCoQuan.trungUong.toJson(), 'trung_uong');
      expect(CapCoQuan.tinh.toJson(), 'tinh');
      expect(CapCoQuan.huyen.toJson(), 'huyen');
      expect(CapCoQuan.xa.toJson(), 'xa');

      expect(CapCoQuan.fromJson('trung_uong'), CapCoQuan.trungUong);
      expect(CapCoQuan.fromJson('tinh'), CapCoQuan.tinh);
      expect(CapCoQuan.fromJson('huyen'), CapCoQuan.huyen);
      expect(CapCoQuan.fromJson('xa'), CapCoQuan.xa);
    });

    test('TrangThaiThuTuc serialization matches schema', () {
      expect(TrangThaiThuTuc.nhap.toJson(), 'nhap');
      expect(TrangThaiThuTuc.dangDung.toJson(), 'dang_dung');
      expect(TrangThaiThuTuc.ngung.toJson(), 'ngung');

      expect(TrangThaiThuTuc.fromJson('nhap'), TrangThaiThuTuc.nhap);
      expect(TrangThaiThuTuc.fromJson('dang_dung'), TrangThaiThuTuc.dangDung);
      expect(TrangThaiThuTuc.fromJson('ngung'), TrangThaiThuTuc.ngung);
    });

    test('HinhThucBuoc serialization matches schema', () {
      expect(HinhThucBuoc.chung.toJson(), 'chung');
      expect(HinhThucBuoc.trucTuyen.toJson(), 'truc_tuyen');
      expect(HinhThucBuoc.trucTiep.toJson(), 'truc_tiep');
      expect(HinhThucBuoc.buuChinh.toJson(), 'buu_chinh');
      expect(HinhThucBuoc.khac.toJson(), 'khac');

      expect(HinhThucBuoc.fromJson('chung'), HinhThucBuoc.chung);
      expect(HinhThucBuoc.fromJson('truc_tuyen'), HinhThucBuoc.trucTuyen);
      expect(HinhThucBuoc.fromJson('truc_tiep'), HinhThucBuoc.trucTiep);
      expect(HinhThucBuoc.fromJson('buu_chinh'), HinhThucBuoc.buuChinh);
      expect(HinhThucBuoc.fromJson('khac'), HinhThucBuoc.khac);
    });

    test('HinhThucNop serialization matches schema', () {
      expect(HinhThucNop.trucTuyen.toJson(), 'truc_tuyen');
      expect(HinhThucNop.trucTiep.toJson(), 'truc_tiep');
      expect(HinhThucNop.buuChinh.toJson(), 'buu_chinh');
      expect(HinhThucNop.khac.toJson(), 'khac');

      expect(HinhThucNop.fromJson('truc_tuyen'), HinhThucNop.trucTuyen);
      expect(HinhThucNop.fromJson('truc_tiep'), HinhThucNop.trucTiep);
      expect(HinhThucNop.fromJson('buu_chinh'), HinhThucNop.buuChinh);
      expect(HinhThucNop.fromJson('khac'), HinhThucNop.khac);
    });

    test('LoaiVanBan serialization matches schema', () {
      expect(LoaiVanBan.luat.toJson(), 'luat');
      expect(LoaiVanBan.nghiDinh.toJson(), 'nghi_dinh');
      expect(LoaiVanBan.thongTu.toJson(), 'thong_tu');
      expect(LoaiVanBan.quyetDinh.toJson(), 'quyet_dinh');
      expect(LoaiVanBan.nghiQuyet.toJson(), 'nghi_quyet');
      expect(LoaiVanBan.khac.toJson(), 'khac');

      expect(LoaiVanBan.fromJson('luat'), LoaiVanBan.luat);
      expect(LoaiVanBan.fromJson('nghi_dinh'), LoaiVanBan.nghiDinh);
      expect(LoaiVanBan.fromJson('thong_tu'), LoaiVanBan.thongTu);
      expect(LoaiVanBan.fromJson('quyet_dinh'), LoaiVanBan.quyetDinh);
      expect(LoaiVanBan.fromJson('nghi_quyet'), LoaiVanBan.nghiQuyet);
      expect(LoaiVanBan.fromJson('khac'), LoaiVanBan.khac);
    });

    test('TrangThaiHieuLuc serialization matches schema', () {
      expect(TrangThaiHieuLuc.chuaXacMinh.toJson(), 'chua_xac_minh');
      expect(TrangThaiHieuLuc.conHieuLuc.toJson(), 'con_hieu_luc');
      expect(TrangThaiHieuLuc.hetHieuLuc.toJson(), 'het_hieu_luc');

      expect(TrangThaiHieuLuc.fromJson('chua_xac_minh'), TrangThaiHieuLuc.chuaXacMinh);
      expect(TrangThaiHieuLuc.fromJson('con_hieu_luc'), TrangThaiHieuLuc.conHieuLuc);
      expect(TrangThaiHieuLuc.fromJson('het_hieu_luc'), TrangThaiHieuLuc.hetHieuLuc);
    });

    test('VaiTroTinNhan serialization matches schema', () {
      expect(VaiTroTinNhan.user.toJson(), 'user');
      expect(VaiTroTinNhan.assistant.toJson(), 'assistant');
      expect(VaiTroTinNhan.tool.toJson(), 'tool');

      expect(VaiTroTinNhan.fromJson('user'), VaiTroTinNhan.user);
      expect(VaiTroTinNhan.fromJson('assistant'), VaiTroTinNhan.assistant);
      expect(VaiTroTinNhan.fromJson('tool'), VaiTroTinNhan.tool);
    });

    test('TrangThaiTraLoi serialization matches schema', () {
      expect(TrangThaiTraLoi.answered.toJson(), 'answered');
      expect(TrangThaiTraLoi.gate.toJson(), 'gate');
      expect(TrangThaiTraLoi.model.toJson(), 'model');
      expect(TrangThaiTraLoi.guard.toJson(), 'guard');

      expect(TrangThaiTraLoi.fromJson('answered'), TrangThaiTraLoi.answered);
      expect(TrangThaiTraLoi.fromJson('gate'), TrangThaiTraLoi.gate);
      expect(TrangThaiTraLoi.fromJson('model'), TrangThaiTraLoi.model);
      expect(TrangThaiTraLoi.fromJson('guard'), TrangThaiTraLoi.guard);
    });
  });
}
