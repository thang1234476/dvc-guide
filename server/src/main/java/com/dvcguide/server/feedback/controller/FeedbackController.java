package com.dvcguide.server.feedback.controller;

import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.catalog.entity.Agency;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.FeedbackType;
import com.dvcguide.server.feedback.entity.Feedback;
import com.dvcguide.server.procedure.entity.Procedure;
import jakarta.persistence.EntityManager;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/feedback")
@RequiredArgsConstructor
public class FeedbackController {
    private final EntityManager db;

    public record Input(@NotNull FeedbackType type, Integer agencyId, Integer procedureId,
                        @NotBlank @Size(max = 16000) String content) {}

    @PostMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void send(@AuthenticationPrincipal UserSession user, @Valid @RequestBody Input input) {
        if (input.type() == FeedbackType.sai_dia_chi && input.agencyId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cần chọn cơ quan để báo sai địa chỉ.");
        }
        if (input.agencyId() != null && db.find(Agency.class, input.agencyId()) == null) {
            throw new ResourceNotFoundException("Không tìm thấy cơ quan.");
        }
        if (input.procedureId() != null && db.find(Procedure.class, input.procedureId()) == null) {
            throw new ResourceNotFoundException("Không tìm thấy thủ tục.");
        }
        Feedback feedback = new Feedback();
        feedback.setNguoiDungId(user.userId());
        feedback.setLoai(input.type());
        feedback.setCoQuanId(input.agencyId());
        feedback.setThuTucId(input.procedureId());
        feedback.setNoiDung(input.content().strip());
        db.persist(feedback);
    }
}
