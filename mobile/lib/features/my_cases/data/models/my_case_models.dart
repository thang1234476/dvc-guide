import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

part 'my_case_models.freezed.dart';
part 'my_case_models.g.dart';

Map<int, TrangThaiGiayTo> _checklistFromJson(Map<String, dynamic>? json) {
  if (json == null) return {};
  final result = <int, TrangThaiGiayTo>{};
  for (final entry in json.entries) {
    final key = int.tryParse(entry.key);
    if (key == null) continue;
    final val = entry.value;
    if (val is bool) {
      if (val == true) {
        result[key] = TrangThaiGiayTo.daCo;
      }
      // false -> bỏ khóa (chưa rõ)
    } else if (val is String) {
      try {
        final status = TrangThaiGiayTo.fromJson(val);
        if (status != TrangThaiGiayTo.chuaRo) {
          result[key] = status;
        }
      } catch (_) {
        // bỏ qua nếu không hợp lệ
      }
    }
  }
  return result;
}

Map<String, dynamic> _checklistToJson(Map<int, TrangThaiGiayTo> map) {
  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    if (entry.value != TrangThaiGiayTo.chuaRo) {
      result[entry.key.toString()] = entry.value.toJson();
    }
  }
  return result;
}

/// Chuẩn hóa JSON hồ sơ định dạng cũ (trước schema v3) về định dạng mới.
Map<String, dynamic> _normalizeLegacyJson(Map<String, dynamic> input) {
  final json = Map<String, dynamic>.from(input);

  // ten_ho_so: bản cũ không có -> lấy tên thủ tục
  final tenHoSo = json['ten_ho_so'];
  if (tenHoSo is! String || tenHoSo.trim().isEmpty) {
    final thuTuc = json['thu_tuc'];
    final tenThuTuc = thuTuc is Map ? thuTuc['ten'] : null;
    json['ten_ho_so'] = tenThuTuc is String ? tenThuTuc : '';
  }

  // han_tra_kq (cũ) -> ngay_hen
  if (json['ngay_hen'] == null && json['han_tra_kq'] != null) {
    json['ngay_hen'] = json['han_tra_kq'];
  }

  // co_quan_id (cũ) -> co_quan_du_dinh_id
  if (json['co_quan_du_dinh_id'] == null && json['co_quan_id'] != null) {
    json['co_quan_du_dinh_id'] = json['co_quan_id'];
  }

  return json;
}

@freezed
class HoSoCuaToi with _$HoSoCuaToi {
  const HoSoCuaToi._();

  const factory HoSoCuaToi({
    required String id,
    @JsonKey(name: 'ten_ho_so') required String tenHoSo,
    @JsonKey(name: 'thu_tuc') required ThuTucSummary thuTuc,
    @JsonKey(name: 'truong_hop_id') int? truongHopId,
    @Default(TrangThaiHoSo.dangChuanBi) @JsonKey(name: 'trang_thai') TrangThaiHoSo trangThai,
    @JsonKey(name: 'co_quan_du_dinh_id') int? coQuanDuDinhId,
    @JsonKey(name: 'co_quan_thuc_te_id') int? coQuanThucTeId,
    @JsonKey(name: 'ngay_nop') DateTime? ngayNop,
    @JsonKey(name: 'ma_ho_so') String? maHoSo,
    @JsonKey(name: 'ngay_hen') DateTime? ngayHen,
    @JsonKey(name: 'ghi_chu') String? ghiChu,
    @JsonKey(name: 'tao_luc') DateTime? taoLuc,
    @JsonKey(name: 'cap_nhat_luc') DateTime? capNhatLuc,
    @JsonKey(name: 'checklist', fromJson: _checklistFromJson, toJson: _checklistToJson)
    @Default({})
    Map<int, TrangThaiGiayTo> checklist,
  }) = _HoSoCuaToi;

  /// Backward-compatibility getters
  DateTime? get hanTraKq => ngayHen;
  int? get coQuanId => coQuanDuDinhId ?? coQuanThucTeId;

    factory HoSoCuaToi.fromJson(Map<String, dynamic> json) =>
      _$HoSoCuaToiFromJson(_normalizeLegacyJson(json));
}

/// Pure function to filter applicable papers for a case / truongHop.
/// Returns both general papers (truongHopId == null) and case-specific papers (truongHopId == truongHopId).
List<ThanhPhanHoSo> filterApplicablePapers(
  List<ThanhPhanHoSo> allPapers,
  int? truongHopId,
) {
  return allPapers.where((p) {
    if (truongHopId == null) {
      return p.truongHopId == null;
    }
    return p.truongHopId == null || p.truongHopId == truongHopId;
  }).toList();
}
