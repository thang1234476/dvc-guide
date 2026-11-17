package com.dvcguide.server.config;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

/**
 * Application-level configuration properties.
 * Reads from application.yml under 'integration.ai-service'.
 */
@Configuration
@Validated
@ConfigurationProperties(prefix = "integration.ai-service")
public class ApplicationConfig {

    @NotBlank
    private String baseUrl = "http://localhost:8000";
    @Min(1)
    private int timeoutSeconds = 55;

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public int getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public void setTimeoutSeconds(int timeoutSeconds) {
        this.timeoutSeconds = timeoutSeconds;
    }
}
