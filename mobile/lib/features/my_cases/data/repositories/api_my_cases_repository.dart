import 'package:dio/dio.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/domain/repositories/my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

/// Hồ sơ của tôi lưu trên server (/api/v1/dossiers).
///
/// Lưu ý về server:
///  - PUT /dossiers/{id} ghi đè toàn bộ, nên mọi lần sửa đều GET hồ sơ hiện tại,
///    đổi field cần sửa rồi PUT cả bộ.
///  - Server không trả thông tin đầy đủ của thủ tục, chỉ có id và tên.
///  - Xóa là xóa hẳn. "Hoàn tác" phải tạo lại hồ sơ (id mới).
class ApiMyCasesRepository implements MyCasesRepository {
  ApiMyCasesRepository(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/dossiers';

  /// Nhớ lại ThuTucSummary đầy đủ khi app tự tạo hồ sơ (server chỉ trả id + tên).
  static final Map<int, ThuTucSummary> _summaries = {};

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _obj(Response<dynamic> res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static String? _fmt(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  static DateTime? _parseDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static HoSoCuaToi _toCase(
    Map<String, dynamic> j, {
    Map<int, TrangThaiGiayTo> checklist = const {},
  }) {
    final procedureId = (j['procedureId'] as num).toInt();
    final summary = _summaries[procedureId] ??
        ThuTucSummary(
          id: procedureId,
          maThuTuc: '',
          ten: (j['procedureName'] as String?) ?? '',
        );
    return HoSoCuaToi(
      id: j['id'] as String,
      tenHoSo: (j['name'] as String?) ?? '',
      thuTuc: summary,
      truongHopId: (j['caseId'] as num?)?.toInt(),
      trangThai: TrangThaiHoSo.fromJson(j['status'] as String),
      coQuanDuDinhId: (j['intendedAgencyId'] as num?)?.toInt(),
      coQuanThucTeId: (j['actualAgencyId'] as num?)?.toInt(),
      ngayNop: _parseDate(j['submittedDate']),
      maHoSo: j['reference'] as String?,
      ngayHen: _parseDate(j['appointmentDate']),
      ghiChu: j['notes'] as String?,
      capNhatLuc: _parseDate(j['updatedAt'])?.toLocal(),
      checklist: checklist,
    );
  }

  Future<List<Map<String, dynamic>>> _listViews() async {
    final all = <Map<String, dynamic>>[];
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final res = await _dio
          .get(_base, queryParameters: {'page': page, 'size': 100});
      final data = _obj(res);
      for (final item in (data['items'] as List)) {
        all.add(item as Map<String, dynamic>);
      }
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      page++;
    }
    return all;
  }

  Future<Map<String, dynamic>> _getView(String id) async =>
      _obj(await _dio.get('$_base/$id'));

  Future<Map<int, TrangThaiGiayTo>> _fetchChecklist(String id) async {
    try {
      final res = await _dio.get('$_base/$id/checklist');
      final list = (res.data as Map<String, dynamic>)['data'] as List;
      final map = <int, TrangThaiGiayTo>{};
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final status = TrangThaiGiayTo.fromJson(m['status'] as String);
        if (status != TrangThaiGiayTo.chuaRo) {
          map[(m['documentId'] as num).toInt()] = status;
        }
      }
      return map;
    } on DioException {
      return {};
    }
  }

  Map<String, dynamic> _bodyFrom(Map<String, dynamic> cur) => {
        'name': cur['name'],
        'caseId': cur['caseId'],
        'status': cur['status'],
        'intendedAgencyId': cur['intendedAgencyId'],
        'actualAgencyId': cur['actualAgencyId'],
        'submittedDate': cur['submittedDate'],
        'reference': cur['reference'],
        'appointmentDate': cur['appointmentDate'],
        'notes': cur['notes'],
      };

  /// GET hồ sơ hiện tại, cho [change] sửa, rồi PUT cả bộ.
  Future<Map<String, dynamic>> _update(
    String id,
    void Function(Map<String, dynamic> body) change,
  ) async {
    final body = _bodyFrom(await _getView(id));
    change(body);
    return _obj(await _dio.put('$_base/$id', data: body));
  }

  static String _uniqueName(Set<String> names, String baseName) {
    if (!names.contains(baseName)) return baseName;
    var index = 2;
    while (names.contains('$baseName ($index)')) {
      index++;
    }
    return '$baseName ($index)';
  }

  Future<Map<String, dynamic>> _create({
    required ThuTucSummary thuTuc,
    required String name,
    int? caseId,
    TrangThaiHoSo? trangThai,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    String? ghiChu,
  }) async {
    var view = _obj(await _dio.post(_base, data: {
      'name': name,
      'procedureId': thuTuc.id,
      'caseId': caseId,
    }));
    _summaries[thuTuc.id] = thuTuc;

    final needsUpdate = (trangThai != null &&
            trangThai != TrangThaiHoSo.dangChuanBi) ||
        coQuanDuDinhId != null ||
        coQuanThucTeId != null ||
        ngayNop != null ||
        (maHoSo != null && maHoSo.isNotEmpty) ||
        ngayHen != null ||
        (ghiChu != null && ghiChu.isNotEmpty);

    if (needsUpdate) {
      view = await _update(view['id'] as String, (b) {
        if (trangThai != null) b['status'] = trangThai.toJson();
        b['intendedAgencyId'] = coQuanDuDinhId;
        b['actualAgencyId'] = coQuanThucTeId;
        b['submittedDate'] = _fmt(ngayNop);
        b['reference'] = maHoSo;
        b['appointmentDate'] = _fmt(ngayHen);
        b['notes'] = ghiChu;
      });
    }
    return view;
  }

  // ── MyCasesRepository ─────────────────────────────────────────────────────

  @override
  Future<List<HoSoCuaToi>> getMyCases() async {
    final views = await _listViews();
    final cases = await Future.wait(views.map((v) async {
      final checklist = await _fetchChecklist(v['id'] as String);
      return _toCase(v, checklist: checklist);
    }));
    return cases; // server đã sắp xếp theo cập nhật gần nhất
  }

  @override
  Future<HoSoCuaToi?> getCaseById(String id) async {
    try {
      final view = await _getView(id);
      final checklist = await _fetchChecklist(id);
      return _toCase(view, checklist: checklist);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId) async {
    final all = await getMyCases();
    return all.where((c) => c.thuTuc.id == thuTucId).toList();
  }

  @override
  Future<HoSoCuaToi> addCase({
    required ThuTucSummary thuTuc,
    String? tenHoSo,
    int? truongHopId,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    int? coQuanId,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    DateTime? hanTraKq,
    String? ghiChu,
    TrangThaiHoSo? trangThai,
    List<int>? allThanhPhanIds, // server tự lấy giấy tờ theo thủ tục
  }) async {
    final names =
        (await _listViews()).map((v) => v['name'] as String).toSet();
    final baseName = (tenHoSo != null && tenHoSo.trim().isNotEmpty)
        ? tenHoSo.trim()
        : thuTuc.ten;

    final view = await _create(
      thuTuc: thuTuc,
      name: _uniqueName(names, baseName),
      caseId: truongHopId,
      trangThai: trangThai,
      coQuanDuDinhId: coQuanDuDinhId ?? coQuanId,
      coQuanThucTeId: coQuanThucTeId,
      ngayNop: ngayNop,
      maHoSo: maHoSo,
      ngayHen: ngayHen ?? hanTraKq,
      ghiChu: ghiChu,
    );
    return _toCase(view);
  }

  @override
  Future<void> updateCase(
    String id, {
    String? tenHoSo,
    TrangThaiHoSo? trangThai,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    bool clearDuDinh = false,
    bool clearThucTe = false,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    String? ghiChu,
    int? truongHopId,
  }) async {
    await _update(id, (b) {
      if (tenHoSo != null) b['name'] = tenHoSo;
      if (trangThai != null) b['status'] = trangThai.toJson();
      if (clearDuDinh) {
        b['intendedAgencyId'] = null;
      } else if (coQuanDuDinhId != null) {
        b['intendedAgencyId'] = coQuanDuDinhId;
      }
      if (clearThucTe) {
        b['actualAgencyId'] = null;
      } else if (coQuanThucTeId != null) {
        b['actualAgencyId'] = coQuanThucTeId;
      }
      if (ngayNop != null) b['submittedDate'] = _fmt(ngayNop);
      if (maHoSo != null) b['reference'] = maHoSo;
      if (ngayHen != null) b['appointmentDate'] = _fmt(ngayHen);
      if (ghiChu != null) b['notes'] = ghiChu;
      if (truongHopId != null) b['caseId'] = truongHopId;
    });
  }

  @override
  Future<void> setGiayToStatus(
    String caseId,
    int thanhPhanId,
    TrangThaiGiayTo status,
  ) async {
    await _dio.put(
      '$_base/$caseId/checklist/$thanhPhanId',
      data: {'status': status.toJson()},
    );
  }

  @override
  Future<void> toggleChecklist(
    String hoSoId,
    int thanhPhanId,
    bool isReady,
  ) async {
    await setGiayToStatus(
      hoSoId,
      thanhPhanId,
      isReady ? TrangThaiGiayTo.daCo : TrangThaiGiayTo.chuaRo,
    );
  }

  @override
  Future<void> updateDates(
    String hoSoId, {
    DateTime? ngayNop,
    DateTime? hanTraKq,
    DateTime? ngayHen,
  }) async {
    await updateCase(hoSoId, ngayNop: ngayNop, ngayHen: ngayHen ?? hanTraKq);
  }

  /// null = bỏ chọn trường hợp (ghi đè thật sự, khác với updateCase).
  @override
  Future<void> updateTruongHop(String hoSoId, int? truongHopId) async {
    await _update(hoSoId, (b) => b['caseId'] = truongHopId);
  }

  /// null = bỏ chọn cơ quan dự định.
  @override
  Future<void> updateCoQuan(String hoSoId, int? coQuanId) async {
    await _update(hoSoId, (b) => b['intendedAgencyId'] = coQuanId);
  }

  @override
  Future<void> deleteCase(String id) async {
    await _dio.delete('$_base/$id');
  }

  /// Hoàn tác xóa: tạo lại hồ sơ (id mới) rồi đánh dấu lại giấy tờ.
  /// [index] không dùng vì server tự sắp xếp.
  @override
  Future<void> restoreCase(HoSoCuaToi caseToRestore, int index) async {
    final view = await _create(
      thuTuc: caseToRestore.thuTuc,
      name: caseToRestore.tenHoSo,
      caseId: caseToRestore.truongHopId,
      trangThai: caseToRestore.trangThai,
      coQuanDuDinhId: caseToRestore.coQuanDuDinhId,
      coQuanThucTeId: caseToRestore.coQuanThucTeId,
      ngayNop: caseToRestore.ngayNop,
      maHoSo: caseToRestore.maHoSo,
      ngayHen: caseToRestore.ngayHen,
      ghiChu: caseToRestore.ghiChu,
    );
    final newId = view['id'] as String;
    for (final entry in caseToRestore.checklist.entries) {
      try {
        await setGiayToStatus(newId, entry.key, entry.value);
      } on DioException {
        // bỏ qua giấy tờ không còn áp dụng
      }
    }
  }

  @override
  Future<void> clearAll() async {
    final views = await _listViews();
    for (final v in views) {
      await _dio.delete('$_base/${v['id']}');
    }
  }
}