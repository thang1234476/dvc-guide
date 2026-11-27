import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dvc_guide_mobile/core/error/app_exception.dart';
import 'package:dvc_guide_mobile/core/network/api_endpoints.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

import '../../domain/repositories/procedure_repository.dart';
import '../models/procedure_models.dart';

/// Bản thật của [ProcedureRepository], gọi Spring Boot qua Dio.
/// Backend bọc mọi response dạng { success, message, data, timestamp }.
class ApiProcedureRepository implements ProcedureRepository {
  ApiProcedureRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Lĩnh vực ────────────────────────────────────────────────────────────────

  @override
  Future<List<LinhVuc>> getLinhVucList() => _run<List<LinhVuc>>(() async {
    final res = await _dio.get(ApiEndpoints.fields);
    return _maps(_body(res)['data']).map(_linhVuc).toList();
  });

  // ── Danh sách / tìm kiếm ────────────────────────────────────────────────────

  @override
  Future<List<ThuTucSummary>> getProcedures({
    String? query,
    int? linhVucId,
    List<int>? linhVucIds,
    List<int>? onlyIds,
    int page = 1,
    int pageSize = 10,
  }) => _run<List<ThuTucSummary>>(() async {
    final fieldIds = linhVucIds ?? (linhVucId != null ? [linhVucId] : null);
    final keyword = query?.trim() ?? '';

    final res = await _dio.get(
      ApiEndpoints.procedures,
      queryParameters: {
        if (keyword.isNotEmpty)
          'keyword': keyword.length > 250 ? keyword.substring(0, 250) : keyword,
        if (fieldIds != null && fieldIds.isNotEmpty)
          'fieldIds': fieldIds.join(','),
        // onlyIds != null nghĩa là "chỉ thủ tục đã lưu": server tự lọc
        // theo tài khoản đang đăng nhập, nên không cần dùng danh sách id.
        if (onlyIds != null) 'savedOnly': true,
        'page': page < 1 ? 0 : page - 1, // backend đánh trang từ 0
        'size': pageSize,
      },
    );
    final data = _map(_body(res)['data']);
    return _maps(data['items']).map(_summary).toList();
  });


  // ── Chi tiết ────────────────────────────────────────────────────────────────

  @override
  Future<ThuTucDetail> getProcedureDetail(int id) =>
      _run<ThuTucDetail>(() async {
        final res = await _dio.get(ApiEndpoints.procedureById(id));
        return _detail(_map(_body(res)['data']));
      });

  @override
  Future<ThuTucDetail?> getProcedureByMa(String maThuTuc) =>
      _run<ThuTucDetail?>(() async {
        final ma = maThuTuc.trim();
        if (ma.isEmpty) return null;

        // Backend chưa có tra cứu theo mã: tìm theo từ khóa rồi lọc đúng mã.
        final res = await _dio.get(
          ApiEndpoints.procedures,
          queryParameters: {'keyword': ma, 'page': 0, 'size': 20},
        );
        final items = _maps(_map(_body(res)['data'])['items']);
        for (final m in items) {
          if (_str(m['code'])?.trim() == ma) {
            return await getProcedureDetail(_int(m['id'])!);
          }
        }
        return null;
      });

  // ── Cơ quan tiếp nhận ───────────────────────────────────────────────────────

  @override
  Future<List<CoQuan>> getCoQuanTiepNhan({
    required int thuTucId,
    required int diaPhuongId,
  }) => _run<List<CoQuan>>(() async {
    final res = await _dio.get(
      ApiEndpoints.procedureAgencies(thuTucId),
      queryParameters: {'localityId': diaPhuongId},
    );
    final list = _maps(_body(res)['data']).map(_coQuan).toList();
    // Cơ quan đã kiểm chứng xếp trước.
    list.sort((a, b) {
      if (a.daKiemChung == b.daKiemChung) return 0;
      return a.daKiemChung ? -1 : 1;
    });
    return list;
  });

  // ── Chuyển đổi JSON backend -> model của app ────────────────────────────────

  static LinhVuc _linhVuc(Map<String, dynamic> m) => LinhVuc(
    id: _int(m['id'])!,
    ma: _str(m['code']),
    ten: _str(m['name']) ?? '',
  );

  static ThuTucSummary _summary(Map<String, dynamic> m) => ThuTucSummary(
    id: _int(m['id'])!,
    maThuTuc: _str(m['code']) ?? '',
    ten: _str(m['name']) ?? '',
    capThucHien: _enum<CapCoQuan>(_str(m['level']), CapCoQuan.fromJson),
    linhVuc: _maps(m['fields']).map(_linhVuc).toList(),
  );

  static ThuTucDetail _detail(Map<String, dynamic> m) {
    final p = _summary(_map(m['procedure']));

    final results = (m['results'] as List?) ?? const [];
    final cases = _maps(m['cases']);
    final docs = _maps(m['documents']);
    final steps = _maps(m['steps']);

    return ThuTucDetail(
      id: p.id,
      maThuTuc: p.maThuTuc,
      ten: p.ten,
      capThucHien: p.capThucHien,
      coQuanThucHienGoc: _str(m['originalAgency']),
      doiTuong: _str(m['audience']),
      dieuKien: _str(m['conditions']),
      linkDvc: _str(m['portalUrl']),
      linhVuc: p.linhVuc,
      ketQua: [
        for (var i = 0; i < results.length; i++)
          ThuTucKetQua(id: i + 1, ten: '${results[i]}', thuTu: i + 1),
      ],
      coQuan: _maps(m['agencies'])
          .map(
            (a) => ThuTucCoQuanDetail(
              coQuan: _coQuan(a),
              ghiChu: _str(a['notes']),
            ),
          )
          .toList(),
      truongHop: [
        for (var i = 0; i < cases.length; i++)
          TruongHop(
            id: _int(cases[i]['id'])!,
            ten: _str(cases[i]['name']) ?? '',
            dieuKien: _str(cases[i]['conditions']),
            cauHoiPhanLoai: _str(cases[i]['question']),
            thuTu: i,
          ),
      ],
      thanhPhanHoSo: [
        for (var i = 0; i < docs.length; i++) _thanhPhan(docs[i], i),
      ],
      buocThucHien: [for (var i = 0; i < steps.length; i++) _buoc(steps[i], i)],
      hinhThucNop: _maps(m['submissions']).map(_hinhThucNop).toList(),
      vanBan: _maps(m['legalBases']).map(_vanBan).toList(),
    );
  }

  static ThanhPhanHoSo _thanhPhan(Map<String, dynamic> d, int index) {
    final form = d['form'];
    return ThanhPhanHoSo(
      id: _int(d['id'])!,
      truongHopId: _int(d['caseId']),
      nhom: _str(d['group']),
      tenGiayTo: _str(d['name']) ?? '',
      truongHopGoc: _str(d['originalCase']),
      soLuongBanChinh: _int(d['originals']),
      soLuongBanSao: _int(d['copies']),
      batBuoc: d['required'] as bool?,
      bieuMau: form is Map ? _bieuMau(_map(form)) : null,
      ghiChu: _str(d['notes']),
      thuTu: index,
    );
  }

  static BieuMau _bieuMau(Map<String, dynamic> f) => BieuMau(
    id: _int(f['id'])!,
    ten: _str(f['name']) ?? '',
    fileDocxUrl: _str(f['docxUrl']),
    filePdfUrl: _str(f['pdfUrl']),
  );

  static BuocThucHien _buoc(Map<String, dynamic> s, int index) => BuocThucHien(
    id: _int(s['id'])!,
    hinhThuc:
        _enum<HinhThucBuoc>(_str(s['channel']), HinhThucBuoc.fromJson) ??
        HinhThucBuoc.chung,
    thuTu: _int(s['order']) ?? index + 1,
    tieuDe: _str(s['title']),
    moTa: _str(s['description']),
    anhHuongDanUrl: _str(s['imageUrl']),
  );

  static HinhThucNopChiTiet _hinhThucNop(Map<String, dynamic> s) {
    final fees = _maps(s['fees']);
    return HinhThucNopChiTiet(
      id: _int(s['id'])!,
      hinhThuc:
          _enum<HinhThucNop>(_str(s['channel']), HinhThucNop.fromJson) ??
          HinhThucNop.khac,
      hinhThucGoc: _str(s['originalChannel']),
      thoiHanSo: _dbl(s['duration']),
      thoiHanDonVi: _str(s['durationUnit']),
      thoiHanGoc: _str(s['originalDuration']),
      linkNop: _str(s['url']),
      diaChiNop: _str(s['address']),
      gioTiepNhan: _str(s['openingHours']),
      lePhi: [
        for (var i = 0; i < fees.length; i++)
          LePhi(
            id: _int(fees[i]['id'])!,
            mienPhi: (fees[i]['free'] as bool?) ?? false,
            soTien: _dbl(fees[i]['amount']),
            tienTe: _str(fees[i]['currency']),
            ghiChu: _str(fees[i]['notes']),
            thuTu: i + 1,
          ),
      ],
    );
  }

  static VanBanPhapLyChiTiet _vanBan(Map<String, dynamic> v) =>
      VanBanPhapLyChiTiet(
        id: _int(v['id'])!,
        soHieu: _str(v['reference']) ?? '',
        ten: _str(v['name']) ?? '',
        loai:
            _enum<LoaiVanBan>(_str(v['type']), LoaiVanBan.fromJson) ??
            LoaiVanBan.khac,
        coQuanBanHanh: _str(v['issuer']),
        ngayBanHanh: _str(v['issuedDate']),
        ngayHieuLuc: _str(v['effectiveDate']),
        ngayHetHieuLuc: _str(v['expiryDate']),
        trangThaiHieuLuc:
            _enum<TrangThaiHieuLuc>(
              _str(v['validity']),
              TrangThaiHieuLuc.fromJson,
            ) ??
            TrangThaiHieuLuc.chuaXacMinh,
        url: _str(v['url']),
        dieuKhoan: _str(v['article']) ?? '',
      );

  static CoQuan _coQuan(Map<String, dynamic> a) => CoQuan(
    id: _int(a['id'])!,
    ma: _str(a['code']),
    ten: _str(a['name']) ?? '',
    cap:
        _enum<CapCoQuan>(_str(a['level']), CapCoQuan.fromJson) ??
        CapCoQuan.tinh,
    diaChi: _str(a['address']),
    diaPhuongId: _int(a['localityId']),
    viDo: _dbl(a['latitude']),
    kinhDo: _dbl(a['longitude']),
    soDienThoai: _str(a['phone']),
    email: _str(a['email']),
    website: _str(a['website']),
    gioLamViec: _str(a['workingHours']),
    gioPhatSo: _str(a['ticketHours']),
    nguonDiaChi:
        _enum<NguonDiaChi>(_str(a['addressSource']), NguonDiaChi.fromJson) ??
        NguonDiaChi.duLieuGoc,
    daKiemChung: (a['verified'] as bool?) ?? false,
    kiemChungLuc: _str(a['verifiedAt']),
  );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static int? _int(Object? v) => (v as num?)?.toInt();
  static double? _dbl(Object? v) => (v as num?)?.toDouble();
  static String? _str(Object? v) => v as String?;

  static Map<String, dynamic> _map(Object? v) =>
      (v as Map).cast<String, dynamic>();

  static List<Map<String, dynamic>> _maps(Object? v) =>
      ((v as List?) ?? const []).map(_map).toList();

  static Map<String, dynamic> _body(Response res) {
    final raw = res.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    throw const FormatException('Response không phải JSON object');
  }

  /// Enum lạ hoặc null -> trả null để dùng giá trị mặc định thay vì crash.
  static T? _enum<T>(String? v, T Function(String) parse) {
    if (v == null) return null;
    try {
      return parse(v);
    } catch (_) {
      return null;
    }
  }

  /// Giữ nguyên AppException do ErrorInterceptor tạo ra để UI xử lý như cũ.
  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is AppException) throw inner;
      rethrow;
    }
  }
}
