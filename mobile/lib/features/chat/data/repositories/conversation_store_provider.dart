import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/repositories/conversation_store.dart';
import 'shared_pref_conversation_store.dart';

final conversationStoreProvider = Provider<ConversationStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefConversationStore(prefs);
});
