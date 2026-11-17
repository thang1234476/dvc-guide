package com.dvcguide.server.procedure.controller;

import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.dto.ProcedureSummary;
import com.dvcguide.server.procedure.service.ProcedureService;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/procedures")
@RequiredArgsConstructor
public class ProcedureController {
    private final ProcedureService procedures;

    @GetMapping
    public ApiResponse<PageResponse<ProcedureSummary>> search(
            @RequestParam(defaultValue = "") @Size(max = 250) String keyword,
            @RequestParam(required = false) @Size(max = 50) List<Integer> fieldIds,
            @RequestParam(defaultValue = "false") boolean savedOnly,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
            @AuthenticationPrincipal UserSession session) {
        return ApiResponse.success(procedures.search(keyword, fieldIds == null ? List.of() : fieldIds,
                savedOnly, session == null ? null : session.userId(), page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<ProcedureDetail> detail(@PathVariable int id, @AuthenticationPrincipal UserSession session) {
        return ApiResponse.success(procedures.detail(id, session == null ? null : session.userId()));
    }

    @GetMapping("/{id}/agencies")
    public ApiResponse<List<ProcedureDetail.Agency>> agencies(@PathVariable int id,
                                                              @RequestParam(required = false) Integer localityId) {
        return ApiResponse.success(procedures.agencies(id, localityId));
    }
}
