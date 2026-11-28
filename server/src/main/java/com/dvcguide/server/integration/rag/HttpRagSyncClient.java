package com.dvcguide.server.integration.rag;

import com.dvcguide.server.config.ApplicationConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;

@Component
public class HttpRagSyncClient implements RagSyncClient {
    private final RestClient client;
    private final ApplicationConfig config;

    public HttpRagSyncClient(RestClient.Builder builder, ApplicationConfig config,
                             @Value("${integration.rag-sync.timeout-seconds:180}") int timeout) {
        this.config = config;
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(3));
        factory.setReadTimeout(Duration.ofSeconds(timeout));
        client = builder.baseUrl(config.getBaseUrl()).requestFactory(factory).build();
    }

    @Override
    public Result sync(int id, Payload payload) {
        if (config.getApiKey().isBlank()) throw new IllegalStateException("Chưa cấu hình AI_SERVICE_API_KEY cho backend.");
        return client.put().uri("/api/v1/rag/procedures/{id}", id).header("X-API-Key", config.getApiKey())
                .contentType(MediaType.APPLICATION_JSON).body(payload).retrieve().body(Result.class);
    }
}
