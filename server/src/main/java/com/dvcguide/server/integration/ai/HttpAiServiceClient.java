package com.dvcguide.server.integration.ai;

import com.dvcguide.server.common.model.AnswerStatus;
import com.dvcguide.server.config.ApplicationConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.util.stream.Collectors;

@Component
public class HttpAiServiceClient implements AiServiceClient {
    private final RestClient client;
    private final ApplicationConfig config;

    @Autowired
    public HttpAiServiceClient(RestClient.Builder builder, ApplicationConfig config) {
        this(configure(builder, config), config);
    }

    public HttpAiServiceClient(RestClient client, ApplicationConfig config) {
        this.client = client;
        this.config = config;
    }

    private static RestClient configure(RestClient.Builder builder, ApplicationConfig config) {
        var requests = new SimpleClientHttpRequestFactory();
        requests.setConnectTimeout(Duration.ofSeconds(3));
        requests.setReadTimeout(Duration.ofSeconds(config.getTimeoutSeconds()));
        return builder.baseUrl(config.getBaseUrl()).requestFactory(requests).build();
    }

    @Override
    public Answer query(Query request) {
        Answer result;
        try {
            if (config.getApiKey().isBlank()) throw unavailable(null);
            result = client.post()
                    .uri("/api/v1/rag/query")
                    .header("X-API-Key", config.getApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(Answer.class);
        } catch (RestClientException exception) {
            throw unavailable(exception);
        }

        var availableCodes = request.sources().isEmpty() && request.allowedProcedures() != null
                ? request.allowedProcedures().stream().map(Version::code).collect(Collectors.toSet())
                : request.sources().stream().map(Source::code).collect(Collectors.toSet());
        if (result == null || result.answer() == null || result.answer().isBlank()
                || result.how() == null || result.latencyMs() == null || result.latencyMs() < 0
                || result.sourceCodes() == null || !availableCodes.containsAll(result.sourceCodes())
                || (result.how() == AnswerStatus.answered && result.sourceCodes().isEmpty())
                || (result.model() != null && result.model().length() > 50)) {
            throw unavailable(null);
        }
        if (request.sources().isEmpty() && !result.sourceCodes().isEmpty()) {
            if (request.allowedProcedures() == null || result.sourceVersions() == null
                    || !request.allowedProcedures().containsAll(result.sourceVersions())
                    || !result.sourceVersions().stream().map(Version::code).collect(Collectors.toSet()).containsAll(result.sourceCodes())) {
                throw unavailable(null);
            }
        }
        return result;
    }

    private ResponseStatusException unavailable(Throwable cause) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "Trợ lý AI tạm thời chưa thể trả lời. Vui lòng thử lại sau.", cause);
    }
}
