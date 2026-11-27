import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import '../../domain/repositories/gop_y_repository.dart';

class MockGopYItem {
  final int id;
  final LoaiGopY loai;
  final String noiDung;
  final int? coQuanId;
  final int? thuTucId;
  final DateTime taoLuc;

  MockGopYItem({
    required this.id,
    required this.loai,
    required this.noiDung,
    this.coQuanId,
    this.thuTucId,
    required this.taoLuc,
  });
}

/// In-memory mock implementation of [GopYRepository]
class MockGopYRepository implements GopYRepository {
  final List<MockGopYItem> _items = [];
  int _nextId = 1;

  @override
  Future<void> submit({
    required LoaiGopY loai,
    required String noiDung,
    int? coQuanId,
    int? thuTucId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.add(
      MockGopYItem(
        id: _nextId++,
        loai: loai,
        noiDung: noiDung,
        coQuanId: coQuanId,
        thuTucId: thuTucId,
        taoLuc: DateTime.now(),
      ),
    );
  }

  List<MockGopYItem> get submittedItems => List.unmodifiable(_items);
}
