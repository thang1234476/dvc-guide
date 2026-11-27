import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_models.dart';

class MockChatRepository implements ChatRepository {
  int _nextId = 10;
  final List<TinNhan> _messages = [
    TinNhan(
      id: 1,
      vaiTro: VaiTroTinNhan.assistant,
      noiDung:
          'Xin chào! Tôi là Trợ lý số hướng dẫn thủ tục hành chính công. Bạn có thể hỏi tôi về hồ sơ, điều kiện, lệ phí và quy trình thực hiện các thủ tục hành chính.',
      nguonTrichDan: const [],
      trangThaiTraLoi: TrangThaiTraLoi.answered,
      diemTop1: 1.0,
      doTreMs: 150,
      modelPhienBan: 'mock-dvc-v1.0',
      taoLuc: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final List<PhanHoi> _feedbacks = [];

  @override
  Future<List<TinNhan>> getInitialMessages() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_messages);
  }

  @override
  Future<TinNhan> sendMessage(
    String text, {
    String? maThuTucContext,
    Map<String, dynamic>? thamSo,
  }) async {
    // Latency 1-2s simulation
    await Future.delayed(const Duration(milliseconds: 1300));
    final search = VietnameseUtils.toSearchable(text);

    // 0. Handle paper-specific context (thamSo contains ten_giay_to / thanh_phan_ho_so_id)
    if (thamSo != null && (thamSo['ten_giay_to'] != null || thamSo['thanh_phan_ho_so_id'] != null)) {
      final paperName = thamSo['ten_giay_to'] as String? ?? 'giấy tờ này';
      final citations = (maThuTucContext != null && maThuTucContext.isNotEmpty)
          ? [maThuTucContext]
          : const <String>[];
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Về giấy tờ "$paperName": Đây là thành phần trong hồ sơ thủ tục hành chính. Bạn cần chuẩn bị đúng số lượng bản chính hoặc bản sao theo quy định và nộp kèm theo hồ sơ.',
        nguonTrichDan: citations,
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.98,
        doTreMs: 1200,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    // 1. Trigger error test
    if (search.contains('loi') || search.contains('error')) {
      throw Exception('Lỗi kết nối giả lập: Máy chủ không phản hồi câu hỏi này.');
    }

    // 2. Trigger guard test (out-of-scope question)
    if (search.contains('thoi tiet') ||
        search.contains('bong da') ||
        search.contains('xem boi') ||
        search.contains('gia vang')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung: AppStrings.guardCardTitle,
        nguonTrichDan: const [],
        trangThaiTraLoi: TrangThaiTraLoi.guard,
        diemTop1: 0.1,
        doTreMs: 450,
        modelPhienBan: 'guard-filter-v1',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    // 3. Trigger model test (unverified AI generation)
    if (search.contains('model') || search.contains('thu nghiem')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Đây là nội dung thử nghiệm do mô hình AI tự sinh để kiểm tra giao diện trạng thái model. Câu trả lời này chưa được đối chiếu với cơ sở dữ liệu pháp luật hiện hành.',
        nguonTrichDan: const [],
        trangThaiTraLoi: TrangThaiTraLoi.model,
        diemTop1: 0.65,
        doTreMs: 1100,
        modelPhienBan: 'experimental-llm-v2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    // 4. Handle questions with procedure context
    if (maThuTucContext != null && maThuTucContext.isNotEmpty) {
      if (search.contains('ho so') || search.contains('giay to')) {
        final res = TinNhan(
          id: ++_nextId,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung:
              'Hồ sơ của thủ tục này bao gồm Tờ khai theo mẫu quy định cùng các giấy tờ chứng minh nhân thân và điều kiện áp dụng. Bạn có thể nhấn vào nguồn trích dẫn bên dưới để xem danh sách giấy tờ chi tiết cho từng trường hợp cụ thể.',
          nguonTrichDan: [maThuTucContext],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          diemTop1: 0.96,
          doTreMs: 1250,
          modelPhienBan: 'rag-gemini-v1.2',
          taoLuc: DateTime.now(),
        );
        _messages.add(res);
        return res;
      }

      if (search.contains('thoi gian') || search.contains('bao lau') || search.contains('thoi han')) {
        final res = TinNhan(
          id: ++_nextId,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung:
              'Thời hạn giải quyết thủ tục được tính theo ngày làm việc kể từ thời điểm cơ quan có thẩm quyền tiếp nhận đầy đủ hồ sơ hợp lệ. Thông tin chi tiết cho từng hình thức nộp trực tiếp hay trực tuyến được ghi rõ trong nguồn thủ tục.',
          nguonTrichDan: [maThuTucContext],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          diemTop1: 0.95,
          doTreMs: 1280,
          modelPhienBan: 'rag-gemini-v1.2',
          taoLuc: DateTime.now(),
        );
        _messages.add(res);
        return res;
      }

      if (search.contains('le phi') || search.contains('tien') || search.contains('chi phi')) {
        final res = TinNhan(
          id: ++_nextId,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung:
              'Mức thu lệ phí thực hiện thủ tục áp dụng theo quy định hiện hành của Bộ Tài chính hoặc Hội đồng nhân dân cấp tỉnh. Vui lòng xem chi tiết mục Lệ phí trong thủ tục được trích dẫn bên dưới.',
          nguonTrichDan: [maThuTucContext],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          diemTop1: 0.93,
          doTreMs: 1210,
          modelPhienBan: 'rag-gemini-v1.2',
          taoLuc: DateTime.now(),
        );
        _messages.add(res);
        return res;
      }
    }

    // 5. Handle standard procedure keywords
    if (search.contains('khai sinh')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Đối với thủ tục Đăng ký khai sinh cho trẻ em, cha mẹ cần nộp Tờ khai đăng ký khai sinh và Giấy chứng sinh trong thời hạn 60 ngày kể từ ngày sinh. Thủ tục được thực hiện tại UBND cấp xã nơi cư trú của cha hoặc mẹ và hoàn toàn miễn phí.',
        nguonTrichDan: const ['1.000123.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.98,
        doTreMs: 1350,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('ket hon')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Đăng ký kết hôn yêu cầu hai bên nam nữ có mặt trực tiếp tại UBND cấp xã nơi thường trú hoặc tạm trú của một trong hai bên. Hồ sơ gồm Tờ khai kết hôn và Giấy xác nhận tình trạng hôn nhân (nếu nộp tại nơi tạm trú). Đăng ký giữa công dân Việt Nam trong nước được miễn lệ phí.',
        nguonTrichDan: const ['1.000456.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.97,
        doTreMs: 1400,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('can cuoc') || search.contains('cccd')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Theo Luật Căn cước 2023, công dân đổi thẻ khi đến các độ tuổi 14, 25, 40 và 60 tuổi hoặc khi thẻ hư hỏng. Quá trình thu nhận sẽ chụp ảnh gương mặt, lấy vân tay và thu nhận mống mắt. Lệ phí đổi thẻ là 50.000 đ, cấp lại khi mất là 70.000 đ.',
        nguonTrichDan: const ['2.001789.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.96,
        doTreMs: 1320,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('thuong tru') || search.contains('ho khau')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Để đăng ký thường trú vào chỗ ở hợp pháp, bạn cần chuẩn bị Tờ khai thay đổi thông tin cư trú (Mẫu CT01) và giấy tờ chứng minh chỗ ở hợp pháp (như Sổ hồng hoặc Hợp đồng thuê nhà có đồng ý của chủ sở hữu). Thời hạn giải quyết là 07 ngày làm việc.',
        nguonTrichDan: const ['1.002345.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.94,
        doTreMs: 1270,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('ly lich tu phap') || search.contains('lltp')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Thủ tục cấp Phiếu lý lịch tư pháp được nộp qua ứng dụng VNeID, Cổng dịch vụ công hoặc tại Trung tâm Phục vụ hành chính công cấp tỉnh. Lệ phí thông thường là 200.000 đ/lần, học sinh sinh viên được giảm còn 100.000 đ.',
        nguonTrichDan: const ['1.003456.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.95,
        doTreMs: 1310,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('ho kinh doanh')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Thành lập hộ kinh doanh thực hiện tại Phòng Tài chính - Kế hoạch thuộc UBND cấp huyện. Hồ sơ gồm Giấy đề nghị đăng ký hộ kinh doanh và bản sao CCCD của chủ hộ. Thời hạn giải quyết là 03 ngày làm việc.',
        nguonTrichDan: const ['1.004567.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.93,
        doTreMs: 1360,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    if (search.contains('so do') || search.contains('dat dai') || search.contains('nha dat')) {
      final res = TinNhan(
        id: ++_nextId,
        vaiTro: VaiTroTinNhan.assistant,
        noiDung:
            'Cấp Giấy chứng nhận quyền sử dụng đất lần đầu nộp tại Chi nhánh Văn phòng Đăng ký đất đai cấp huyện hoặc Bộ phận Một cửa. Cần nộp Đơn đăng ký (mẫu 04a/ĐK) kèm giấy tờ chứng minh nguồn gốc đất và chứng từ thực hiện nghĩa vụ tài chính.',
        nguonTrichDan: const ['1.005678.000.00.00.H56'],
        trangThaiTraLoi: TrangThaiTraLoi.answered,
        diemTop1: 0.92,
        doTreMs: 1390,
        modelPhienBan: 'rag-gemini-v1.2',
        taoLuc: DateTime.now(),
      );
      _messages.add(res);
      return res;
    }

    // 6. Gate fallback (Strict adherence to accuracy)
    final res = TinNhan(
      id: ++_nextId,
      vaiTro: VaiTroTinNhan.assistant,
      noiDung: AppStrings.gateFallbackAnswer,
      nguonTrichDan: const [],
      trangThaiTraLoi: TrangThaiTraLoi.gate,
      diemTop1: 0.35,
      doTreMs: 850,
      modelPhienBan: 'rag-gemini-v1.2',
      taoLuc: DateTime.now(),
    );
    _messages.add(res);
    return res;
  }

  @override
  Future<void> sendFeedback(PhanHoi feedback) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _feedbacks.removeWhere((f) => f.tinNhanId == feedback.tinNhanId);
    _feedbacks.add(feedback);
  }

  @override
  Future<void> setFeedback(int tinNhanId, bool huuIch) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _feedbacks.removeWhere((f) => f.tinNhanId == tinNhanId);
    _feedbacks.add(PhanHoi(tinNhanId: tinNhanId, huuIch: huuIch));
  }

  List<PhanHoi> get feedbacks => List.unmodifiable(_feedbacks);
}
