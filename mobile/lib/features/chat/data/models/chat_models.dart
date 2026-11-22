import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/enums/procedure_enums.dart';

part 'chat_models.freezed.dart';
part 'chat_models.g.dart';

@freezed
class TinNhan with _$TinNhan {
  const factory TinNhan({
    required int id,
    @JsonKey(name: 'vai_tro') required VaiTroTinNhan vaiTro,
    @JsonKey(name: 'noi_dung') required String noiDung,
    @Default([]) @JsonKey(name: 'nguon_trich_dan') List<String> nguonTrichDan,
    @JsonKey(name: 'trang_thai_tra_loi') TrangThaiTraLoi? trangThaiTraLoi,
    @JsonKey(name: 'diem_top1') double? diemTop1,
    @JsonKey(name: 'do_tre_ms') int? doTreMs,
    @JsonKey(name: 'model_phien_ban') String? modelPhienBan,
    @JsonKey(name: 'tao_luc') required DateTime taoLuc,
  }) = _TinNhan;

  factory TinNhan.fromJson(Map<String, dynamic> json) => _$TinNhanFromJson(json);
}

@freezed
class PhanHoi with _$PhanHoi {
  const factory PhanHoi({
    @JsonKey(name: 'tin_nhan_id') required int tinNhanId,
    @JsonKey(name: 'huu_ich') bool? huuIch,
    @JsonKey(name: 'ghi_chu') String? ghiChu,
  }) = _PhanHoi;

  factory PhanHoi.fromJson(Map<String, dynamic> json) => _$PhanHoiFromJson(json);
}

@freezed
class ChatConversation with _$ChatConversation {
  @JsonSerializable(explicitToJson: true)
  const factory ChatConversation({
    required String id,
    @JsonKey(name: 'tieu_de') required String tieuDe,
    @JsonKey(name: 'thu_tuc_id') int? thuTucId,
    @JsonKey(name: 'tao_luc') required DateTime taoLuc,
    @JsonKey(name: 'cap_nhat_luc') required DateTime capNhatLuc,
    @Default([]) @JsonKey(name: 'tin_nhan') List<TinNhan> tinNhan,
  }) = _ChatConversation;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationFromJson(json);
}
