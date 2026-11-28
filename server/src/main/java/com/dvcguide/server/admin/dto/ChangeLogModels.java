package com.dvcguide.server.admin.dto;

import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.entity.ChangeLog;
import com.dvcguide.server.common.model.ChangeAction;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.Instant;

public final class ChangeLogModels {
    private ChangeLogModels() {}

    public record Filter(@Positive Integer administratorId, @Size(max = 64) String tableName,
                         @Size(max = 64) String recordId, ChangeAction action,
                         @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
                         @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        @AssertTrue(message = "Thời điểm bắt đầu phải trước hoặc bằng thời điểm kết thúc.")
        @JsonIgnore
        public boolean isTimeRangeValid() {
            return from == null || to == null || !from.isAfter(to);
        }
    }

    public record Actor(int id, String name) {}

    public record Summary(long id, Integer administratorId, String administratorName, String tableName,
                          String recordId, ChangeAction action, Instant createdAt) {}

    public record Response(long id, Integer administratorId, String administratorName, String tableName,
                           String recordId, ChangeAction action, JsonNode before, JsonNode after,
                           Instant createdAt) {

        public static Response from(ChangeLog log, Administrator admin) {
            String name = admin == null ? null : admin.getTenHienThi() == null || admin.getTenHienThi().isBlank()
                    ? admin.getEmail() : admin.getTenHienThi();
            return new Response(log.getId(), log.getQuanTriId(), name,
                    log.getBang(), log.getBanGhiId(), log.getHanhDong(), log.getDuLieuTruoc(), log.getDuLieuSau(),
                    log.getTaoLuc());
        }
    }
}
