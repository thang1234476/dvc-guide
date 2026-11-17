package com.dvcguide.server.chat.controller;

import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.chat.dto.ConversationDtos.Create;
import com.dvcguide.server.chat.dto.ConversationDtos.Exchange;
import com.dvcguide.server.chat.dto.ConversationDtos.MessageView;
import com.dvcguide.server.chat.dto.ConversationDtos.Rate;
import com.dvcguide.server.chat.dto.ConversationDtos.RatingView;
import com.dvcguide.server.chat.dto.ConversationDtos.Send;
import com.dvcguide.server.chat.dto.ConversationDtos.Summary;
import com.dvcguide.server.chat.service.ChatService;
import com.dvcguide.server.chat.service.ConversationService;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/conversations")
@RequiredArgsConstructor
@Tag(name = "Conversations")
@SecurityRequirement(name = "userBearer")
public class ConversationController {
    private final ConversationService conversations;
    private final ChatService chat;

    @GetMapping
    public ApiResponse<PageResponse<Summary>> list(@AuthenticationPrincipal UserSession user,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(conversations.list(user.userId(), page, size));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Summary> create(@AuthenticationPrincipal UserSession user, @Valid @RequestBody Create body) {
        return ApiResponse.success(conversations.create(user.userId(), body));
    }

    @GetMapping("/{id}")
    public ApiResponse<Summary> detail(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        return ApiResponse.success(conversations.detail(user.userId(), id));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        conversations.delete(user.userId(), id);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAll(@AuthenticationPrincipal UserSession user) {
        conversations.deleteAll(user.userId());
    }

    @GetMapping("/{id}/messages")
    public ApiResponse<PageResponse<MessageView>> history(@AuthenticationPrincipal UserSession user,
            @PathVariable String id,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(conversations.history(user.userId(), id, page, size));
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Exchange> send(@AuthenticationPrincipal UserSession user, @PathVariable String id,
                                      @Valid @RequestBody Send body) {
        return ApiResponse.success(chat.send(user.userId(), id, body.content()));
    }

    @PutMapping("/{id}/messages/{messageId}/rating")
    public ApiResponse<RatingView> rate(@AuthenticationPrincipal UserSession user, @PathVariable String id,
                                        @PathVariable @Positive long messageId, @Valid @RequestBody Rate body) {
        return ApiResponse.success(conversations.rate(user.userId(), id, messageId, body));
    }
}
