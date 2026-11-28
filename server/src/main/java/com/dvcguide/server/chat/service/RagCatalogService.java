package com.dvcguide.server.chat.service;

import com.dvcguide.server.common.model.AnswerStatus;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.integration.ai.AiServiceClient;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RagCatalogService {
    private final ProcedureRepository procedures;

    @Transactional(readOnly = true)
    public List<AiServiceClient.Version> published() {
        var rows = procedures.findByTrangThaiOrderById(ProcedureStatus.dang_dung);
        if (rows.size() > 10000) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Danh mục AI vượt giới hạn cấu hình.");
        return rows.stream().map(p -> new AiServiceClient.Version(p.getId(), p.getMaThuTuc(), p.getPhienBan())).toList();
    }

    @Transactional(readOnly = true)
    public AiServiceClient.Answer validateCurrent(AiServiceClient.Query query, AiServiceClient.Answer answer) {
        if (answer.sourceCodes().isEmpty()) return answer;
        Map<String, AiServiceClient.Version> expected = query.allowedProcedures().stream()
                .collect(Collectors.toMap(AiServiceClient.Version::code, Function.identity()));
        for (String code : answer.sourceCodes()) {
            var wanted = expected.get(code);
            var current = procedures.findByMaThuTuc(code).orElse(null);
            if (wanted == null || current == null || current.getTrangThai() != ProcedureStatus.dang_dung
                    || current.getId() != wanted.procedureId() || current.getPhienBan() != wanted.version()) {
                return new AiServiceClient.Answer("Nội dung thủ tục vừa thay đổi hoặc đã ngừng áp dụng. Vui lòng hỏi lại để nhận dữ liệu mới.",
                        List.of(), AnswerStatus.gate, answer.latencyMs(), answer.model());
            }
        }
        return answer;
    }
}
