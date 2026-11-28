package com.dvcguide.server.integration.ai;

import com.dvcguide.server.common.model.AnswerStatus;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

public interface AiServiceClient {
    Answer query(Query request);

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Source(@JsonProperty("procedure_id") int procedureId, String code, String title, String content, Integer version) {
        public Source(int id, String code, String title, String content) { this(id, code, title, content, null); }
    }

    record Version(@JsonProperty("procedure_id") int procedureId, String code, int version) {}

    record Turn(String role, String content) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Query(String question, List<Source> sources, List<Turn> history,
                 @JsonProperty("allowed_procedures") List<Version> allowedProcedures) {
        public Query(String question, List<Source> sources, List<Turn> history) { this(question, sources, history, null); }
    }

    record Answer(String answer, @JsonProperty("source_codes") List<String> sourceCodes,
                  AnswerStatus how, @JsonProperty("latency_ms") Integer latencyMs, String model,
                  @JsonProperty("source_versions") List<Version> sourceVersions) {
        public Answer(String answer, List<String> codes, AnswerStatus how, Integer latency, String model) {
            this(answer, codes, how, latency, model, List.of());
        }
    }
}
