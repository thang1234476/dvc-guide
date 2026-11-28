package com.dvcguide.server.chat.service;

import com.dvcguide.server.chat.dto.ConversationDtos.Exchange;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.integration.ai.AiServiceClient;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.service.ProcedureService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.dvcguide.server.chat.service.ConversationService.limitText;

@Service
@RequiredArgsConstructor
public class ChatService {
    private final ConversationService conversations;
    private final ProcedureService procedures;
    private final AiServiceClient ai;
    private final RagCatalogService catalog;

    public Exchange send(String userId, String id, String content) {
        var snapshot = conversations.snapshot(userId, id);
        String question = content.strip();
        var sources = loadSources(snapshot.procedureId());
        var allowed = snapshot.procedureId() != null && sources.isEmpty() ? List.<AiServiceClient.Version>of() : catalog.published();
        var request = new AiServiceClient.Query(question, sources, snapshot.history(), allowed);
        var answer = catalog.validateCurrent(request, ai.query(request));
        return conversations.append(userId, id, snapshot, question, answer);
    }

    private List<AiServiceClient.Source> loadSources(Integer procedureId) {
        if (procedureId == null) {
            return List.of();
        }
        ProcedureDetail detail;
        try {
            detail = procedures.detail(procedureId, null);
        } catch (ResourceNotFoundException ignored) {
            // A procedure linked to an existing conversation may have been retired.
            return List.of();
        }
        var summary = detail.procedure();
        String context = context(detail);
        if (summary.code().isBlank() || summary.name().isBlank() || context.isEmpty()) {
            return List.of();
        }
        return List.of(new AiServiceClient.Source(summary.id(), summary.code().strip(), summary.name(), context, summary.version()));
    }

    private String context(ProcedureDetail detail) {
        StringBuilder content = new StringBuilder();
        append(content, "Thủ tục", detail.procedure().name());
        append(content, "Đối tượng", detail.audience());
        append(content, "Điều kiện", detail.conditions());
        append(content, "Cơ quan thực hiện theo nguồn", detail.originalAgency());
        Map<Integer, String> cases = detail.cases().stream()
                .collect(Collectors.toMap(ProcedureDetail.Case::id, ProcedureDetail.Case::name));
        for (var procedureCase : detail.cases()) {
            append(content, "Trường hợp", procedureCase.name());
            append(content, "Điều kiện của " + limitText(procedureCase.name(), 160), procedureCase.conditions());
        }
        for (var document : detail.documents()) {
            String scope = document.caseId() == null ? document.originalCase() : cases.get(document.caseId());
            String label = scope == null || scope.isBlank()
                    ? "Giấy tờ" : "Giấy tờ (" + limitText(scope, 160) + ")";
            StringBuilder description = new StringBuilder(limitText(document.name(), 440));
            if (document.originals() != null) {
                description.append(" | Bản chính: ").append(document.originals());
            }
            if (document.copies() != null) {
                description.append(" | Bản sao: ").append(document.copies());
            }
            append(content, label, description.toString());
        }
        for (var step : detail.steps()) {
            String label = "Bước " + step.order() + " (" + step.channel() + ")";
            append(content, label, step.title());
            append(content, label + " - nội dung", step.description());
        }
        for (var submission : detail.submissions()) {
            String channel = submission.originalChannel();
            String label = "Cách nộp " + (channel == null || channel.isBlank()
                    ? submission.channel().name() : limitText(channel, 120));
            String duration = submission.originalDuration();
            if ((duration == null || duration.isBlank()) && submission.duration() != null) {
                String unit = submission.durationUnit();
                duration = submission.duration().toPlainString() + (unit == null || unit.isBlank()
                        ? " (đơn vị chưa rõ)" : " " + unit);
            }
            append(content, label + " - thời hạn theo nguồn", duration);
            for (var fee : submission.fees()) {
                String amount = fee.free() ? "Miễn phí" : fee.amount() != null && fee.currency() != null
                        ? fee.amount().toPlainString() + " " + fee.currency() : null;
                append(content, label + " - lệ phí", amount);
                append(content, label + " - ghi chú lệ phí", fee.notes());
            }
        }
        return content.toString().strip();
    }

    private void append(StringBuilder content, String label, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        String line = label + ": " + limitText(value.strip(), 600) + "\n";
        if (content.length() + line.length() <= 6000) {
            content.append(line);
        }
    }
}
