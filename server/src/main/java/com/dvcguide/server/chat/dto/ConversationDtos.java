package com.dvcguide.server.chat.dto;

import com.dvcguide.server.chat.entity.Conversation;
import com.dvcguide.server.common.model.AnswerStatus;
import com.dvcguide.server.common.model.MessageRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

public final class ConversationDtos {
    private ConversationDtos() {}

    public record Create(@Positive Integer procedureId, @Size(max = 500) String title) {}

    public record Send(@NotBlank @Size(max = 2000) String content) {}

    public record Rate(@NotNull Boolean helpful, @Size(max = 1000) String notes) {}

    public record Summary(String id, Integer procedureId, String title, Instant createdAt, Instant updatedAt) {
        public static Summary from(Conversation conversation) {
            return new Summary(conversation.getId(), conversation.getThuTucId(), conversation.getTieuDe(),
                    conversation.getTaoLuc(), conversation.getCapNhatLuc());
        }
    }

    public record MessageView(long id, MessageRole role, String content, AnswerStatus answerStatus,
                              List<String> sourceCodes, Instant createdAt, RatingView rating) {}

    public record RatingView(boolean helpful, String notes) {}

    public record Exchange(MessageView question, MessageView reply) {}
}
