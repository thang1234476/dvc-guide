import 'package:dvc_guide_mobile/features/chat/data/models/chat_models.dart';

abstract class ChatRepository {
  /// Load initial messages in current session
  Future<List<TinNhan>> getInitialMessages();

  /// Send user message and receive AI response with citations, optional procedure context and parameters
  Future<TinNhan> sendMessage(
    String text, {
    String? maThuTucContext,
    Map<String, dynamic>? thamSo,
  });

  /// Send user feedback (helpful or not) on a message
  Future<void> sendFeedback(PhanHoi feedback);

  /// Set or overwrite feedback on a message (one feedback per message, matching schema v3 phan_hoi)
  Future<void> setFeedback(int tinNhanId, bool huuIch);
}
