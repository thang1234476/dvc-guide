package com.dvcguide.server.dossier.controller;

import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.dossier.service.DossierService;
import com.dvcguide.server.dossier.service.DossierService.ChecklistEntry;
import com.dvcguide.server.dossier.service.DossierService.DossierView;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/dossiers")
@RequiredArgsConstructor
public class DossierController {
    private final DossierService dossiers;

    @GetMapping
    public ApiResponse<PageResponse<DossierView>> list(@AuthenticationPrincipal UserSession user,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(dossiers.list(user.userId(), page, size));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<DossierView> create(@AuthenticationPrincipal UserSession user,
                                          @Valid @RequestBody DossierService.Create input) {
        return ApiResponse.success(dossiers.create(user.userId(), input));
    }

    @GetMapping("/{id}")
    public ApiResponse<DossierView> detail(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        return ApiResponse.success(dossiers.detail(user.userId(), id));
    }

    @GetMapping("/{id}/procedure")
    public ApiResponse<ProcedureDetail> procedure(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        return ApiResponse.success(dossiers.procedure(user.userId(), id));
    }

    @PutMapping("/{id}")
    public ApiResponse<DossierView> update(@AuthenticationPrincipal UserSession user, @PathVariable String id,
                                          @Valid @RequestBody DossierService.Update input) {
        return ApiResponse.success(dossiers.update(user.userId(), id, input));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        dossiers.delete(user.userId(), id);
    }

    @GetMapping("/{id}/checklist")
    public ApiResponse<List<ChecklistEntry>> checklist(@AuthenticationPrincipal UserSession user, @PathVariable String id) {
        return ApiResponse.success(dossiers.checklist(user.userId(), id));
    }

    @PutMapping("/{id}/checklist/{documentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void mark(@AuthenticationPrincipal UserSession user, @PathVariable String id, @PathVariable int documentId,
                     @Valid @RequestBody DossierService.ChecklistUpdate input) {
        dossiers.mark(user.userId(), id, documentId, input.status());
    }
}
