package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.dto.ChangeLogModels;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.admin.repository.ChangeLogRepository;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.response.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChangeLogService {
    private final ChangeLogRepository logs;
    private final AdministratorRepository admins;

    public PageResponse<ChangeLogModels.Summary> search(ChangeLogModels.Filter filter, int page, int size) {
        if (!filter.isTimeRangeValid()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Thời điểm bắt đầu phải trước hoặc bằng thời điểm kết thúc.");
        }
        var order = Sort.by(Sort.Order.desc("taoLuc"), Sort.Order.desc("id"));
        return PageResponse.from(logs.search(filter.administratorId(), normalized(filter.tableName()),
                normalized(filter.recordId()), filter.action(), filter.from(), filter.to(), PageRequest.of(page, size, order)));
    }

    public ChangeLogModels.Response detail(long id) {
        var log = logs.findById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nhật ký thay đổi."));
        var actor = log.getQuanTriId() == null ? null : admins.findById(log.getQuanTriId()).orElse(null);
        return ChangeLogModels.Response.from(log, actor);
    }

    public List<ChangeLogModels.Actor> actors() {
        return logs.findActors();
    }

    private String normalized(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }
}
