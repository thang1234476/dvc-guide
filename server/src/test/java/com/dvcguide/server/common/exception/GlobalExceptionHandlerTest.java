package com.dvcguide.server.common.exception;

import com.dvcguide.server.health.HealthController;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Tests for GlobalExceptionHandler.
 * Security is excluded to test handler in isolation.
 */
@WebMvcTest(
    controllers = HealthController.class,
    excludeAutoConfiguration = SecurityAutoConfiguration.class
)
@ActiveProfiles("test")
class GlobalExceptionHandlerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Health endpoint returns 200 with standard ApiResponse structure")
    void healthEndpoint_returnsCorrectApiResponseStructure() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andExpect(jsonPath("$.data.status").value("UP"))
                .andExpect(jsonPath("$.timestamp").isNotEmpty());
    }

    @Test
    @DisplayName("ApiResponse error factory creates correct error structure")
    void apiResponse_errorFactory_createsCorrectStructure() {
        var response = com.dvcguide.server.common.response.ApiResponse.error("Something went wrong");
        assert !response.isSuccess();
        assert response.getMessage().equals("Something went wrong");
        assert response.getTimestamp() != null;
        assert response.getData() == null;
    }

    @Test
    @DisplayName("ApiResponse success factory creates correct success structure")
    void apiResponse_successFactory_createsCorrectStructure() {
        var response = com.dvcguide.server.common.response.ApiResponse.success("OK", "payload");
        assert response.isSuccess();
        assert response.getMessage().equals("OK");
        assert response.getData().equals("payload");
        assert response.getTimestamp() != null;
    }
}
