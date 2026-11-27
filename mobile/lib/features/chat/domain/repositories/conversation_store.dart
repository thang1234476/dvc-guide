import '../../../../core/constants/app_strings.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../data/models/chat_models.dart';

abstract class ConversationStore {
  /// Lấy danh sách tất cả các cuộc trò chuyện theo cap_nhat_luc giảm dần
  Future<List<ChatConversation>> getConversations();

  /// Lấy một cuộc trò chuyện theo id
  Future<ChatConversation?> getConversation(String id);

  /// Lưu cuộc trò chuyện (tối đa 50 cuộc, nếu vượt quá sẽ bỏ cuộc cũ nhất)
  Future<void> saveConversation(ChatConversation conversation);

  /// Xóa cuộc trò chuyện theo id
  Future<void> deleteConversation(String id);

  /// Khôi phục cuộc trò chuyện (hỗ trợ hoàn tác)
  Future<void> restoreConversation(ChatConversation conversation, [int? index]);

  /// Xóa toàn bộ cuộc trò chuyện
  Future<void> clearAll();
}

/// Trợ giúp tạo tiêu đề cuộc trò chuyện: lấy từ câu hỏi đầu tiên của người dùng,
/// cắt 50 ký tự (thêm "..."), không có thì "Cuộc trò chuyện mới".
String generateConversationTitle(List<TinNhan> messages) {
  final firstUserMessage = messages.cast<TinNhan?>().firstWhere(
    (m) =>
        m != null &&
        m.vaiTro == VaiTroTinNhan.user &&
        m.noiDung.trim().isNotEmpty,
    orElse: () => null,
  );
  if (firstUserMessage == null) {
    return AppStrings.newConversation;
  }
  final text = firstUserMessage.noiDung.trim();
  if (text.length <= 50) {
    return text;
  }
  return '${text.substring(0, 50)}...';
}
