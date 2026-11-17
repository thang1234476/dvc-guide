package com.dvcguide.server.integration.ai;

import com.dvcguide.server.common.model.AnswerStatus;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public interface AiServiceClient {
    Answer query(Query request);

    record Source(@JsonProperty("procedure_id") int procedureId, String code, String title, String content) {}

    record Turn(String role, String content) {}

    record Query(String question, List<Source> sources, List<Turn> history) {}

    record Answer(String answer, @JsonProperty("source_codes") List<String> sourceCodes,
                  AnswerStatus how, @JsonProperty("latency_ms") Integer latencyMs, String model) {}
}
