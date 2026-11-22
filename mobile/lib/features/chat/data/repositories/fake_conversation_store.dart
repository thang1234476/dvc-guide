import '../../../../shared/enums/procedure_enums.dart';
import '../../domain/repositories/conversation_store.dart';
import '../models/chat_models.dart';

class FakeConversationStore implements ConversationStore {
  final List<ChatConversation> _items = [];
  static const int kMaxConversations = 50;

  FakeConversationStore([List<ChatConversation>? initial]) {
    if (initial != null) {
      _items.addAll(initial);
      _items.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
    }
  }

  @override
  Future<List<ChatConversation>> getConversations() async {
    _items.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
    return List.unmodifiable(_items);
  }

  @override
  Future<ChatConversation?> getConversation(String id) async {
    return _items.cast<ChatConversation?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    final hasUserMsg =
        conversation.tinNhan.any((m) => m.vaiTro == VaiTroTinNhan.user);
    if (!hasUserMsg || conversation.tinNhan.isEmpty) {
      return;
    }

    final index = _items.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _items[index] = conversation;
    } else {
      _items.add(conversation);
    }

    _items.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
    if (_items.length > kMaxConversations) {
      _items.removeRange(kMaxConversations, _items.length);
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    _items.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restoreConversation(
    ChatConversation conversation, [
    int? index,
  ]) async {
    _items.removeWhere((c) => c.id == conversation.id);
    if (index != null && index >= 0 && index <= _items.length) {
      _items.insert(index, conversation);
    } else {
      _items.add(conversation);
    }
    _items.sort((a, b) => b.capNhatLuc.compareTo(a.capNhatLuc));
    if (_items.length > kMaxConversations) {
      _items.removeRange(kMaxConversations, _items.length);
    }
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }
}
