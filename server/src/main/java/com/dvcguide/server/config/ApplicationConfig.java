package com.dvcguide.server.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Application-level configuration properties.
 * Reads from application.yml under 'integration.ai-service'.
 */
@Configuration
@ConfigurationProperties(prefix = "integration.ai-service")
public class ApplicationConfig {

    private String baseUrl = "http://localhost:8000";
    private int timeoutSeconds = 30;

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
