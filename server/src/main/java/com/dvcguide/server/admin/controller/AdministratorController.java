package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.AdministratorResponse;
import com.dvcguide.server.admin.dto.CreateAdministratorRequest;
import com.dvcguide.server.admin.service.AdministratorService;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/accounts")
@RequiredArgsConstructor
public class AdministratorController {
    private final AdministratorService admins;

    @GetMapping
    public ApiResponse<PageResponse<AdministratorResponse>> list(
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(admins.list(page, size));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AdministratorResponse> create(@Valid @RequestBody CreateAdministratorRequest request) {
        return ApiResponse.success(admins.create(request));
    }
}
