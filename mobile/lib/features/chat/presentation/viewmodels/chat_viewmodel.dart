import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/features/chat/data/models/chat_models.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/chat_repository_provider.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/conversation_store_provider.dart';
import 'package:dvc_guide_mobile/features/chat/domain/repositories/conversation_store.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

class ChatState {
  final bool isLoading;
  final bool isTyping;
  final List<TinNhan> messages;
  final String? maThuTucContext;
  final String? contextProcedureName;
  final String? tenGiayToContext;
  final int? thanhPhanHoSoIdContext;
  final int? truongHopIdContext;
  final Map<int, bool?> feedbacks; // tinNhanId -> true/false/null
  final String? lastFailedText;
  final String? error;
  final String? conversationId;
  final DateTime? conversationCreatedAt;
  final String? conversationTitle;

  const ChatState({
    this.isLoading = false,
    this.isTyping = false,
    this.messages = const [],
    this.maThuTucContext,
    this.contextProcedureName,
    this.tenGiayToContext,
    this.thanhPhanHoSoIdContext,
    this.truongHopIdContext,
    this.feedbacks = const {},
    this.lastFailedText,
    this.error,
    this.conversationId,
    this.conversationCreatedAt,
    this.conversationTitle,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isTyping,
    List<TinNhan>? messages,
    String? maThuTucContext,
    bool clearMaThuTuc = false,
    String? contextProcedureName,
    bool clearContextName = false,
    String? tenGiayToContext,
    bool clearGiayTo = false,
    int? thanhPhanHoSoIdContext,
    int? truongHopIdContext,
    Map<int, bool?>? feedbacks,
    String? lastFailedText,
    bool clearFailedText = false,
    String? error,
    bool clearError = false,
    String? conversationId,
    bool clearConversationId = false,
    DateTime? conversationCreatedAt,
    bool clearConversationCreatedAt = false,
    String? conversationTitle,
    bool clearConversationTitle = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      messages: messages ?? this.messages,
      maThuTucContext:
          clearMaThuTuc ? null : (maThuTucContext ?? this.maThuTucContext),
      contextProcedureName: clearContextName
          ? null
          : (contextProcedureName ?? this.contextProcedureName),
      tenGiayToContext:
          clearGiayTo ? null : (tenGiayToContext ?? this.tenGiayToContext),
      thanhPhanHoSoIdContext: clearGiayTo
          ? null
          : (thanhPhanHoSoIdContext ?? this.thanhPhanHoSoIdContext),
      truongHopIdContext: clearGiayTo
          ? null
          : (truongHopIdContext ?? this.truongHopIdContext),
      feedbacks: feedbacks ?? this.feedbacks,
      lastFailedText:
          clearFailedText ? null : (lastFailedText ?? this.lastFailedText),
      error: clearError ? null : (error ?? this.error),
      conversationId: clearConversationId
          ? null
          : (conversationId ?? this.conversationId),
      conversationCreatedAt: clearConversationCreatedAt
          ? null
          : (conversationCreatedAt ?? this.conversationCreatedAt),
      conversationTitle: clearConversationTitle
          ? null
          : (conversationTitle ?? this.conversationTitle),
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatViewModel(this._ref, {String? initialMaThuTuc})
      : super(const ChatState(isLoading: true)) {
    init(initialMaThuTuc);
  }

  Future<void> init(String? initialMaThuTuc) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      final initialMessages = await chatRepo.getInitialMessages();

      String? procedureName;
      if (initialMaThuTuc != null && initialMaThuTuc.isNotEmpty) {
        final procedureRepo = _ref.read(procedureRepositoryProvider);
        final proc = await procedureRepo.getProcedureByMa(initialMaThuTuc);
        procedureName = proc?.ten;
      }

      state = state.copyWith(
        isLoading: false,
        messages: initialMessages,
        maThuTucContext: initialMaThuTuc,
        contextProcedureName: procedureName,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setContextProcedure(String? maThuTuc) async {
    if (maThuTuc == null) {
      state = state.copyWith(clearMaThuTuc: true, clearContextName: true);
      return;
    }
    final procedureRepo = _ref.read(procedureRepositoryProvider);
    final proc = await procedureRepo.getProcedureByMa(maThuTuc);
    state = state.copyWith(
      maThuTucContext: maThuTuc,
      contextProcedureName: proc?.ten ?? maThuTuc,
    );
  }

  void setContextGiayTo(
    String? tenGiayTo, {
    int? thanhPhanHoSoId,
    int? truongHopId,
  }) {
    if (tenGiayTo == null) {
      state = state.copyWith(clearGiayTo: true);
    } else {
      state = state.copyWith(
        tenGiayToContext: tenGiayTo,
        thanhPhanHoSoIdContext: thanhPhanHoSoId,
        truongHopIdContext: truongHopId,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isTyping) return;

    final userMessage = TinNhan(
      id: DateTime.now().millisecondsSinceEpoch,
      vaiTro: VaiTroTinNhan.user,
      noiDung: trimmed,
      nguonTrichDan: const [],
      taoLuc: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      clearError: true,
      clearFailedText: true,
    );

    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      final thamSo = (state.thanhPhanHoSoIdContext != null ||
              state.truongHopIdContext != null ||
              state.tenGiayToContext != null)
          ? <String, dynamic>{
              if (state.truongHopIdContext != null) 'truong_hop_id': state.truongHopIdContext,
              if (state.thanhPhanHoSoIdContext != null)
                'thanh_phan_ho_so_id': state.thanhPhanHoSoIdContext,
              if (state.tenGiayToContext != null) 'ten_giay_to': state.tenGiayToContext,
            }
          : null;

      final response = await chatRepo.sendMessage(
        trimmed,
        maThuTucContext: state.maThuTucContext,
        thamSo: thamSo,
      );

      state = state.copyWith(
        messages: [...state.messages, response],
        isTyping: false,
      );

      // Tự động lưu cuộc trò chuyện sau mỗi lượt trả lời xong
      await saveCurrentConversation();
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        lastFailedText: trimmed,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Tự động lưu cuộc hiện tại vào ConversationStore
  Future<void> saveCurrentConversation() async {
    final hasUserMessage =
        state.messages.any((m) => m.vaiTro == VaiTroTinNhan.user);
    if (!hasUserMessage) return; // cuộc rỗng không lưu

    final store = _ref.read(conversationStoreProvider);
    final convId = state.conversationId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = state.conversationCreatedAt ?? DateTime.now();
    final updatedAt = DateTime.now();
    final title =
        state.conversationTitle ?? generateConversationTitle(state.messages);

    // Bỏ qua tin nhắn đang gửi dở hay tin nhắn lỗi
    final validMessages =
        state.messages.where((m) => m.noiDung.trim().isNotEmpty).toList();
    if (validMessages.isEmpty) return;

    final conv = ChatConversation(
      id: convId,
      tieuDe: title,
      thuTucId: state.thanhPhanHoSoIdContext ??
          (int.tryParse(state.maThuTucContext ?? '')),
      taoLuc: createdAt,
      capNhatLuc: updatedAt,
      tinNhan: validMessages,
    );

    await store.saveConversation(conv);
    state = state.copyWith(
      conversationId: convId,
      conversationCreatedAt: createdAt,
      conversationTitle: title,
    );
  }

  /// Nạp một cuộc trò chuyện đã lưu để chat tiếp vào cùng id
  Future<void> loadConversation(ChatConversation conversation) async {
    state = state.copyWith(
      conversationId: conversation.id,
      conversationCreatedAt: conversation.taoLuc,
      conversationTitle: conversation.tieuDe,
      messages: conversation.tinNhan,
      feedbacks: {},
      clearError: true,
      clearFailedText: true,
      clearGiayTo: true,
      clearMaThuTuc: true,
      clearContextName: true,
    );
  }

  void retryLastFailed() {
    if (state.lastFailedText != null) {
      final text = state.lastFailedText!;
      state = state.copyWith(clearFailedText: true, clearError: true);
      sendMessage(text);
    }
  }

  Future<void> toggleFeedback(int tinNhanId, bool isHelpful, {String? note}) async {
    final current = state.feedbacks[tinNhanId];
    if (current == isHelpful && (note == null || note.isEmpty)) {
      // Bấm lại nút đang chọn thì giữ nguyên, KHÔNG bỏ chọn được
      return;
    }

    final updatedMap = Map<int, bool?>.from(state.feedbacks);
    updatedMap[tinNhanId] = isHelpful;
    state = state.copyWith(feedbacks: updatedMap);

    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      if (note != null && note.isNotEmpty) {
        await chatRepo.sendFeedback(
          PhanHoi(
            tinNhanId: tinNhanId,
            huuIch: isHelpful,
            ghiChu: note,
          ),
        );
      } else {
        await chatRepo.setFeedback(tinNhanId, isHelpful);
      }
    } catch (_) {
      // Feedback sending failure doesn't block conversation
    }
  }

  Future<void> clearConversation() async {
    // Lưu cuộc hiện tại trước nếu có nội dung
    await saveCurrentConversation();

    final chatRepo = _ref.read(chatRepositoryProvider);
    final initialMessages = await chatRepo.getInitialMessages();
    state = state.copyWith(
      messages: initialMessages,
      clearConversationId: true,
      clearConversationCreatedAt: true,
      clearConversationTitle: true,
      feedbacks: {},
      clearError: true,
      clearFailedText: true,
    );
  }
}

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, ChatState, String?>(
  (ref, initialMaThuTuc) {
    return ChatViewModel(ref, initialMaThuTuc: initialMaThuTuc);
  },
);
