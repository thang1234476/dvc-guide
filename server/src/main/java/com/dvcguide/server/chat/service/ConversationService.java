package com.dvcguide.server.chat.service;

import com.dvcguide.server.account.repository.UserAccountRepository;
import com.dvcguide.server.chat.dto.ConversationDtos.Create;
import com.dvcguide.server.chat.dto.ConversationDtos.Exchange;
import com.dvcguide.server.chat.dto.ConversationDtos.MessageView;
import com.dvcguide.server.chat.dto.ConversationDtos.Rate;
import com.dvcguide.server.chat.dto.ConversationDtos.RatingView;
import com.dvcguide.server.chat.dto.ConversationDtos.Summary;
import com.dvcguide.server.chat.entity.Conversation;
import com.dvcguide.server.chat.entity.Message;
import com.dvcguide.server.chat.entity.MessageRating;
import com.dvcguide.server.chat.repository.ConversationRepository;
import com.dvcguide.server.chat.repository.MessageRatingRepository;
import com.dvcguide.server.chat.repository.MessageRepository;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.MessageRole;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.integration.ai.AiServiceClient;
import com.dvcguide.server.procedure.service.ProcedureService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ConversationService {
    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final MessageRatingRepository ratings;
    private final UserAccountRepository users;
    private final ProcedureService procedures;
    private final ObjectMapper json;

    record ChatSnapshot(Integer procedureId, Long latestMessageId, List<AiServiceClient.Turn> history) {}

    public PageResponse<Summary> list(String userId, int page, int size) {
        return PageResponse.from(conversations.findByNguoiDungIdOrderByCapNhatLucDescIdDesc(
                userId, PageRequest.of(page, size)).map(Summary::from));
    }

    public Summary detail(String userId, String id) {
        return Summary.from(findOwned(userId, id));
    }

    @Transactional
    public Summary create(String userId, Create request) {
        lockUser(userId);
        String title = request.title() == null || request.title().isBlank() ? null : request.title().strip();
        if (request.procedureId() != null) {
            var procedure = procedures.findPublished(request.procedureId());
            if (title == null) {
                title = limitText(procedure.getTen(), 500);
            }
        }
        Conversation conversation = new Conversation();
        conversation.setNguoiDungId(userId);
        conversation.setThuTucId(request.procedureId());
        conversation.setTieuDe(title);
        return Summary.from(conversations.saveAndFlush(conversation));
    }

    @Transactional
    public void delete(String userId, String id) {
        conversations.delete(lockOwned(userId, id));
    }

    @Transactional
    public void deleteAll(String userId) {
        lockUser(userId);
        conversations.deleteOwned(userId);
    }

    public PageResponse<MessageView> history(String userId, String id, int page, int size) {
        findOwned(userId, id);
        var rows = messages.findByHoiThoaiIdOrderByIdDesc(id, PageRequest.of(page, size));
        var assistantIds = rows.getContent().stream().filter(message -> message.getVaiTro() == MessageRole.assistant)
                .map(Message::getId).toList();
        Map<Long, RatingView> byMessage = assistantIds.isEmpty() ? Map.of() : ratings.findByTinNhanIdIn(assistantIds)
                .stream().collect(Collectors.toMap(MessageRating::getTinNhanId, this::viewRating));
        return PageResponse.from(rows.map(message -> viewMessage(message, byMessage.get(message.getId()))));
    }

    public ChatSnapshot snapshot(String userId, String id) {
        var conversation = findOwned(userId, id);
        Long latestMessageId = messages.latestId(id);
        var turns = new ArrayList<>(messages.findTop6ByHoiThoaiIdAndVaiTroInAndNoiDungIsNotNullOrderByIdDesc(
                        id, List.of(MessageRole.user, MessageRole.assistant)).stream()
                .filter(message -> !message.getNoiDung().isBlank())
                .map(message -> new AiServiceClient.Turn(message.getVaiTro().name(), limitText(message.getNoiDung(), 1000)))
                .toList());
        Collections.reverse(turns);
        return new ChatSnapshot(conversation.getThuTucId(), latestMessageId, turns);
    }

    @Transactional
    public Exchange append(String userId, String id, ChatSnapshot snapshot, String question,
                           AiServiceClient.Answer answer) {
        var conversation = lockOwned(userId, id);
        if (!Objects.equals(messages.latestId(id), snapshot.latestMessageId())
                || !Objects.equals(conversation.getThuTucId(), snapshot.procedureId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Hội thoại đã có thay đổi. Hãy tải lại trước khi gửi câu hỏi.");
        }

        Message userMessage = newMessage(id, MessageRole.user, question);
        messages.save(userMessage);
        Message reply = newMessage(id, MessageRole.assistant, answer.answer());
        reply.setTrangThaiTraLoi(answer.how());
        reply.setNguonTrichDan(json.valueToTree(answer.sourceCodes()));
        reply.setDoTreMs(answer.latencyMs());
        reply.setModelPhienBan(answer.model());
        messages.save(reply);

        if (conversation.getTieuDe() == null) {
            conversation.setTieuDe(limitText(question, 120));
        }
        conversation.setCapNhatLuc(Instant.now());
        return new Exchange(viewMessage(userMessage, null), viewMessage(reply, null));
    }

    @Transactional
    public RatingView rate(String userId, String id, long messageId, Rate request) {
        lockOwned(userId, id);
        if (!messages.existsByIdAndHoiThoaiIdAndVaiTro(messageId, id, MessageRole.assistant)) {
            throw new ResourceNotFoundException("Không tìm thấy câu trả lời trong hội thoại.");
        }
        var rating = ratings.findByTinNhanId(messageId).orElseGet(MessageRating::new);
        rating.setTinNhanId(messageId);
        rating.setHuuIch(request.helpful());
        rating.setGhiChu(request.notes());
        return viewRating(ratings.save(rating));
    }

    private Conversation findOwned(String userId, String id) {
        return conversations.findByIdAndNguoiDungId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hội thoại."));
    }

    private Conversation lockOwned(String userId, String id) {
        return conversations.lockOwned(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hội thoại."));
    }

    private void lockUser(String userId) {
        users.lockById(userId).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản."));
    }

    private Message newMessage(String id, MessageRole role, String content) {
        Message message = new Message();
        message.setHoiThoaiId(id);
        message.setVaiTro(role);
        message.setNoiDung(content);
        return message;
    }

    private MessageView viewMessage(Message message, RatingView rating) {
        var codes = new ArrayList<String>();
        JsonNode sources = message.getNguonTrichDan();
        if (sources != null && sources.isArray()) {
            sources.forEach(source -> {
                if (source.isTextual()) {
                    codes.add(source.textValue());
                }
            });
        }
        return new MessageView(message.getId(), message.getVaiTro(), message.getNoiDung(),
                message.getTrangThaiTraLoi(), codes, message.getTaoLuc(), rating);
    }

    private RatingView viewRating(MessageRating rating) {
        return new RatingView(rating.getHuuIch(), rating.getGhiChu());
    }

    static String limitText(String text, int length) {
        int codePoints = text.codePointCount(0, text.length());
        return codePoints <= length ? text : text.substring(0, text.offsetByCodePoints(0, length));
    }
}
