package com.dvcguide.server.chat;

import com.dvcguide.server.config.ApplicationConfig;
import com.dvcguide.server.integration.ai.*;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.List;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class HttpAiCatalogTest {
    @Test
    void sendsPrivateKeyAndAcceptsMatchingGlobalRagVersions() {
        var builder = RestClient.builder().baseUrl("http://ai.test");
        var server = MockRestServiceServer.bindTo(builder).build();
        var config = config();
        var client = new HttpAiServiceClient(builder.build(), config);
        server.expect(requestTo("http://ai.test/api/v1/rag/query")).andExpect(header("X-API-Key", "test-private-key"))
                .andRespond(withSuccess(answer(2), MediaType.APPLICATION_JSON));
        var query = new AiServiceClient.Query("Lệ phí?", List.of(), List.of(), List.of(new AiServiceClient.Version(1, "CODE", 2)));
        assertThat(client.query(query).sourceCodes()).containsExactly("CODE");
        server.verify();
    }

    @Test
    void rejectsAnOutdatedVersionEvenWhenItsCodeIsStillPublished() {
        var builder = RestClient.builder().baseUrl("http://ai.test");
        var server = MockRestServiceServer.bindTo(builder).build();
        var client = new HttpAiServiceClient(builder.build(), config());
        server.expect(requestTo("http://ai.test/api/v1/rag/query")).andRespond(withSuccess(answer(1), MediaType.APPLICATION_JSON));
        var query = new AiServiceClient.Query("Lệ phí?", List.of(), List.of(), List.of(new AiServiceClient.Version(1, "CODE", 2)));
        assertThatThrownBy(() -> client.query(query)).isInstanceOf(org.springframework.web.server.ResponseStatusException.class);
    }

    private ApplicationConfig config() {
        var config = new ApplicationConfig(); config.setBaseUrl("http://ai.test"); config.setApiKey("test-private-key"); return config;
    }
    private String answer(int version) {
        return "{\"answer\":\"Lệ phí 1000 VND\",\"source_codes\":[\"CODE\"],\"how\":\"answered\",\"latency_ms\":1,\"model\":\"test\","
                + "\"source_versions\":[{\"procedure_id\":1,\"code\":\"CODE\",\"version\":" + version + "}]}";
    }
}
