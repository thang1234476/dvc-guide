package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.ProcedureWriteRequest;
import com.dvcguide.server.admin.service.AdminProcedureService;
import com.dvcguide.server.admin.service.ProcedureExportService;
import com.fasterxml.jackson.databind.node.ObjectNode;
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
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminProcedureController {
    private final AdminProcedureService admin;
    private final ProcedureService reader;
    private final ProcedureExportService exports;

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

    @GetMapping("/procedures/{id}/content")
    public ApiResponse<ObjectNode> content(@PathVariable @Min(1) int id) {
        return ApiResponse.success(exports.content(id));
    }

    @GetMapping("/procedures/export")
    public ResponseEntity<byte[]> exportAll(@RequestParam(defaultValue = "false") boolean activeOnly) {
        return download(exports.all(activeOnly), activeOnly ? "thu-tuc-dang-ap-dung.json" : "thu-tuc-tat-ca.json");
    }

    @GetMapping("/procedures/{id}/export")
    public ResponseEntity<byte[]> exportOne(@PathVariable @Min(1) int id) {
        return download(exports.one(id), "thu-tuc-" + id + ".json");
    }

    private ResponseEntity<byte[]> download(byte[] data, String filename) {
        return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .header(HttpHeaders.CACHE_CONTROL, "no-store").body(data);
    }

    @PostMapping("/procedures")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ProcedureDetail> create(@Valid @RequestBody ProcedureWriteRequest input, Principal actor) {
        return ApiResponse.success(admin.create(input, actor.getName()));
    }

    @PutMapping("/procedures/{id}")
    public ApiResponse<ProcedureDetail> update(@PathVariable int id, @Valid @RequestBody ProcedureWriteRequest input,
                                               Principal actor) {
        return ApiResponse.success(admin.update(id, input, actor.getName()));
    }

    @DeleteMapping("/procedures/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void retire(@PathVariable int id, @RequestParam @Min(1) int version, Principal actor) {
        admin.retire(id, version, actor.getName());
    }
}
