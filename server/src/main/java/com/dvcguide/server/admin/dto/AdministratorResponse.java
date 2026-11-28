package com.dvcguide.server.admin.dto;

import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.common.model.AdminRole;

import java.time.Instant;

public record AdministratorResponse(int id, String email, String displayName, AdminRole role,
                                    boolean active, Instant createdAt) {

    public static AdministratorResponse from(Administrator admin) {
        return new AdministratorResponse(admin.getId(), admin.getEmail(), admin.getTenHienThi(),
                admin.getVaiTro(), admin.getHoatDong(), admin.getTaoLuc());
    }
}
