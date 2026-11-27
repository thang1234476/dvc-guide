import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

/// Repository for submitting user feedback and reports.
/// Corresponds to schema table `gop_y`.
abstract class GopYRepository {
  /// Submit user feedback, bug report, or incorrect address report
  Future<void> submit({
    required LoaiGopY loai,
    required String noiDung,
    int? coQuanId,
    int? thuTucId,
  });
}
