package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.ChangeLogModels;
import com.dvcguide.server.admin.service.ChangeLogService;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.common.response.PageResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/change-logs")
@RequiredArgsConstructor
public class ChangeLogController {
    private final ChangeLogService service;

    @GetMapping
    public ApiResponse<PageResponse<ChangeLogModels.Summary>> search(@Valid @ModelAttribute ChangeLogModels.Filter filter,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(service.search(filter, page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<ChangeLogModels.Response> detail(@PathVariable @Positive long id) {
        return ApiResponse.success(service.detail(id));
    }

    @GetMapping("/administrators")
    public ApiResponse<List<ChangeLogModels.Actor>> actors() {
        return ApiResponse.success(service.actors());
    }
}
