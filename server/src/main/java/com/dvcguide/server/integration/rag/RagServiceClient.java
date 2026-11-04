package com.dvcguide.server.integration.rag;

import java.util.List;
import java.util.Map;

/**
 * Interface for RAG (Retrieval-Augmented Generation) operations.
 * <p>
 * This is a placeholder interface prepared for future integration.
 * The RAG service will handle document retrieval from vector database
 * and augmented generation using Ollama LLM.
 * <p>
 * Future implementation:
 * - Embed user query into vector space
 * - Retrieve relevant document chunks
 * - Pass context to LLM for answer generation
 */
public interface RagServiceClient {

    /**
     * Retrieves relevant document chunks for a given query.
     *
     * @param query      The user's question
     * @param topK       Maximum number of results to return
     * @param collection The document collection to search in
     * @return List of retrieved document chunks with metadata
     * TODO: Replace Map with proper DocumentChunk DTO
     */
    List<Map<String, Object>> retrieve(String query, int topK, String collection);
}
