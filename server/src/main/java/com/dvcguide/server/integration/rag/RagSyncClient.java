package com.dvcguide.server.integration.rag;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;

public interface RagSyncClient {
    Result sync(int id, Payload payload);
    record Payload(int version, String code, boolean active, JsonNode procedure) {}
    record Result(@JsonProperty("procedure_id") int procedureId, int version, String code, boolean active,
                  @JsonProperty("chunk_count") int chunkCount, boolean applied) {}
}
