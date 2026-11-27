import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../domain/repositories/conversation_store.dart';
import '../models/chat_models.dart';

class SharedPrefConversationStore implements ConversationStore {
  final SharedPreferences _prefs;
  static const int kMaxConversations = 50;

  SharedPrefConversationStore(this._prefs);

  List<ChatConversation> _load() {
    final raw = _prefs.getString(AppConstants.kChatConversationsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final conversations = list
          .map((item) => ChatConversation.fromJson(item as Map<String, dynamic>))
          .toList();
      conversations.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
      return conversations;
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<ChatConversation> conversations) async {
    final jsonList = conversations.map((c) => c.toJson()).toList();
    await _prefs.setString(
      AppConstants.kChatConversationsKey,
      jsonEncode(jsonList),
    );
  }

  @override
  Future<List<ChatConversation>> getConversations() async {
    return _load();
  }

  @override
  Future<ChatConversation?> getConversation(String id) async {
    final list = _load();
    return list.cast<ChatConversation?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    // Không lưu cuộc rỗng (không có tin nhắn nào của user)
    final hasUserMsg =
        conversation.tinNhan.any((m) => m.vaiTro == VaiTroTinNhan.user);
    if (!hasUserMsg || conversation.tinNhan.isEmpty) {
      return;
    }

    final list = _load();
    final index = list.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      list[index] = conversation;
    } else {
      list.add(conversation);
    }

    // Sắp xếp giảm dần theo cap_nhat_luc
    list.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));

    // Tối đa 50 cuộc, vượt thì bỏ cuộc cũ nhất
    final trimmedList = list.length > kMaxConversations
        ? list.sublist(0, kMaxConversations)
        : list;

    await _save(trimmedList);
  }

  @override
  Future<void> deleteConversation(String id) async {
    final list = _load();
    list.removeWhere((c) => c.id == id);
    await _save(list);
  }

  @override
  Future<void> restoreConversation(
    ChatConversation conversation, [
    int? index,
  ]) async {
    final list = _load();
    list.removeWhere((c) => c.id == conversation.id);
    if (index != null && index >= 0 && index <= list.length) {
      list.insert(index, conversation);
    } else {
      list.add(conversation);
    }
    list.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
    final trimmedList = list.length > kMaxConversations
        ? list.sublist(0, kMaxConversations)
        : list;
    await _save(trimmedList);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(AppConstants.kChatConversationsKey);
  }
}
