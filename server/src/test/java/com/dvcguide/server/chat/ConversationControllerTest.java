package com.dvcguide.server.chat;

import com.dvcguide.server.account.service.AccountService;
import com.dvcguide.server.common.model.AnswerStatus;
import com.dvcguide.server.integration.ai.AiServiceClient;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ConversationControllerTest {
    private static final String PATH = "/api/v1/conversations";
    private static final AiServiceClient.Answer NO_SOURCES =
            new AiServiceClient.Answer("Chọn một thủ tục để hỏi.", List.of(), AnswerStatus.gate, 0, null);

    @Autowired private MockMvc mvc;
    @Autowired private AccountService accounts;
    @Autowired private ObjectMapper json;

    @MockBean private AiServiceClient ai;

    @Test
    void restrictsConversationsToTheirOwnerAndOverwritesARating() throws Exception {
        String owner = register();
        String other = register();
        String conversation = create(owner);
        given(ai.query(any())).willReturn(NO_SOURCES);

        mvc.perform(get(PATH)).andExpect(status().isUnauthorized());
        mvc.perform(get(conversation).header(HttpHeaders.AUTHORIZATION, other)).andExpect(status().isNotFound());
        send(conversation, other).andExpect(status().isNotFound());
        var exchange = json.readTree(send(conversation, owner).andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.reply.answerStatus").value("gate"))
                .andReturn().getResponse().getContentAsByteArray()).path("data");

        long questionId = exchange.path("question").path("id").asLong();
        long replyId = exchange.path("reply").path("id").asLong();
        rate(conversation, questionId, owner, true).andExpect(status().isNotFound());
        rate(conversation, replyId, other, true).andExpect(status().isNotFound());
        rate(conversation, replyId, owner, true).andExpect(status().isOk());
        rate(conversation, replyId, owner, false).andExpect(status().isOk());
        mvc.perform(get(conversation + "/messages").header(HttpHeaders.AUTHORIZATION, owner))
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.items[0].rating.helpful").value(false));

        String otherConversation = create(other);
        mvc.perform(delete(PATH).header(HttpHeaders.AUTHORIZATION, owner)).andExpect(status().isNoContent());
        mvc.perform(get(conversation).header(HttpHeaders.AUTHORIZATION, owner)).andExpect(status().isNotFound());
        mvc.perform(get(otherConversation).header(HttpHeaders.AUTHORIZATION, other)).andExpect(status().isOk());
    }

    @Test
    void leavesHistoryEmptyWhenAiFailsAndAllowsRetry() throws Exception {
        String owner = register();
        String conversation = create(owner);
        given(ai.query(any())).willThrow(new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE))
                .willReturn(NO_SOURCES);

        send(conversation, owner).andExpect(status().isServiceUnavailable());
        mvc.perform(get(conversation + "/messages").header(HttpHeaders.AUTHORIZATION, owner))
                .andExpect(jsonPath("$.data.totalElements").value(0));
        send(conversation, owner).andExpect(status().isCreated());
        mvc.perform(get(conversation + "/messages").header(HttpHeaders.AUTHORIZATION, owner))
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    void rejectsAnAnswerGeneratedFromStaleHistory() throws Exception {
        String owner = register();
        String conversation = create(owner);
        var barrier = new CyclicBarrier(2);
        given(ai.query(any())).willAnswer(invocation -> {
            barrier.await(10, TimeUnit.SECONDS);
            return NO_SOURCES;
        });

        var executor = Executors.newFixedThreadPool(2);
        try {
            var first = executor.submit(() -> send(conversation, owner).andReturn().getResponse().getStatus());
            var second = executor.submit(() -> send(conversation, owner).andReturn().getResponse().getStatus());
            assertThat(List.of(first.get(15, TimeUnit.SECONDS), second.get(15, TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder(201, 409);
        } finally {
            executor.shutdownNow();
        }
        mvc.perform(get(conversation + "/messages").header(HttpHeaders.AUTHORIZATION, owner))
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    private ResultActions send(String conversation, String token) throws Exception {
        return mvc.perform(post(conversation + "/messages").header(HttpHeaders.AUTHORIZATION, token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"content\":\"Cần chuẩn bị gì?\"}"));
    }

    private ResultActions rate(String conversation, long id, String token, boolean helpful) throws Exception {
        return mvc.perform(put(conversation + "/messages/" + id + "/rating").header(HttpHeaders.AUTHORIZATION, token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"helpful\":" + helpful + "}"));
    }

    private String create(String token) throws Exception {
        byte[] body = mvc.perform(post(PATH).header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsByteArray();
        return PATH + "/" + json.readTree(body).path("data").path("id").asText();
    }

    private String register() {
        var account = accounts.register(new AccountService.Registration(
                UUID.randomUUID() + "@example.test", "test-password-123", null, null));
        return "Bearer " + account.session().token();
    }
}
