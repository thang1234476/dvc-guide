package com.dvcguide.server.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateAdministratorProfileRequest(
        @NotBlank @Size(max = 255) String displayName) {
}
