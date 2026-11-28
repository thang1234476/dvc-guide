package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.ProcedureImportModels.Request;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Confirmation;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Preview;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Result;
import com.dvcguide.server.admin.dto.ProcedureImportModels.DuplicatePolicy;
import com.dvcguide.server.admin.service.ProcedureImportService;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.common.response.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.security.Principal;

@RestController
@RequestMapping("/api/v1/admin/imports")
@RequiredArgsConstructor
public class ProcedureImportController {
    private final ProcedureImportService imports;
    private final ObjectMapper json;

    @PostMapping("/preview")
    public ApiResponse<Preview> preview(@Valid @RequestBody Request input) { return ApiResponse.success(imports.preview(input)); }

    @PostMapping("/preview-file")
    public ApiResponse<Preview> previewFile(@RequestPart MultipartFile file,
            @RequestParam(defaultValue = "SKIP_EXISTING") DuplicatePolicy duplicatePolicy,
            @RequestParam(defaultValue = "dang_dung") ProcedureStatus status) {
        try {
            var data = json.readTree(file.getInputStream());
            if (!data.isArray() || data.isEmpty() || data.size() > 10000) throw new IllegalArgumentException();
            return ApiResponse.success(imports.preview(new Request(json.convertValue(data,
                    json.getTypeFactory().constructCollectionType(java.util.List.class, com.fasterxml.jackson.databind.JsonNode.class)), duplicatePolicy, status)));
        } catch (Exception error) { throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File phải chứa một danh sách JSON có 1 đến 10.000 thủ tục."); }
    }

    @PostMapping("/confirm")
    public ApiResponse<Result> confirm(@Valid @RequestBody Confirmation input, Principal principal) {
        return ApiResponse.success(imports.confirm(input, principal.getName()));
    }
}
