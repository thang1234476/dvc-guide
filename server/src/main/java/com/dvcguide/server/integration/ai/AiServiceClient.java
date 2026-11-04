package com.dvcguide.server.integration.ai;

import java.util.Map;

/**
 * Interface for communicating with the AI/RAG service (Python FastAPI).
 * <p>
 * This is a placeholder interface prepared for future integration.
 * Implementation will call the AI service REST API using RestTemplate or WebClient.
 * <p>
 * Future implementation:
 * - Send user query with context
 * - Receive AI-generated response with source citations
 * - Handle AI service unavailability gracefully
 */
public interface AiServiceClient {

    /**
     * Sends a query to the AI service and returns a response.
     *
     * @param query   The user's question
     * @param context Additional context (e.g., conversation history)
     * @return AI-generated response
     * TODO: Replace Map with proper request/response DTOs
     */
    Map<String, Object> query(String query, Map<String, Object> context);
}
