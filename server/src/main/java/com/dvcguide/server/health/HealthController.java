package com.dvcguide.server.health;

import com.dvcguide.server.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Health check endpoint to verify server is running.
 */
@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health", description = "Server health check")
public class HealthController {

    @GetMapping
    @Operation(
        summary = "Health check",
        description = "Returns server status. Use this to verify the API is running."
    )
    public ResponseEntity<ApiResponse<Map<String, String>>> health() {
        Map<String, String> data = Map.of(
                "status", "UP",
                "service", "dvc-guide-server",
                "version", "0.1.0"
        );
        return ResponseEntity.ok(ApiResponse.success("Server is healthy", data));
    }
}
