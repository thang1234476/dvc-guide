package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.service.AdminProcedureService;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.dto.ProcedureSummary;
import com.dvcguide.server.procedure.service.ProcedureService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminProcedureController {
    private final AdminProcedureService admin;
    private final ProcedureService reader;

    @GetMapping("/me")
    public ApiResponse<AdminProcedureService.AdminProfile> profile(Principal principal) {
        return ApiResponse.success(admin.profile(principal.getName()));
    }

    @GetMapping("/procedures")
    public ApiResponse<PageResponse<ProcedureSummary>> list(
            @RequestParam(defaultValue = "") @Size(max = 250) String keyword,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(reader.searchAdmin(keyword, page, size));
    }

    @GetMapping("/procedures/{id}")
    public ApiResponse<ProcedureDetail> detail(@PathVariable int id) {
        return ApiResponse.success(reader.detailAdmin(id));
    }

    @PostMapping("/procedures")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ProcedureDetail> create(@Valid @RequestBody AdminProcedureService.Input input, Principal actor) {
        return ApiResponse.success(admin.create(input, actor.getName()));
    }

    @PutMapping("/procedures/{id}")
    public ApiResponse<ProcedureDetail> update(@PathVariable int id, @Valid @RequestBody AdminProcedureService.Input input,
                                               Principal actor) {
        return ApiResponse.success(admin.update(id, input, actor.getName()));
    }

    @DeleteMapping("/procedures/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void retire(@PathVariable int id, @RequestParam @Min(1) int version, Principal actor) {
        admin.retire(id, version, actor.getName());
    }
}
