package com.dvcguide.server.admin.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.nio.charset.StandardCharsets;
import java.util.Objects;

public record ChangeAdministratorPasswordRequest(
        @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
        @NotBlank @Size(max = 72) String currentPassword,
        @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
        @NotBlank @Size(min = 12, max = 72) String newPassword,
        @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
        @NotBlank @Size(max = 72) String confirmPassword) {

    @AssertTrue(message = "Mật khẩu tối đa 72 byte UTF-8.")
    @JsonIgnore
    public boolean isPasswordWithinByteLimit() {
        return withinByteLimit(currentPassword) && withinByteLimit(newPassword);
    }

    @AssertTrue(message = "Xác nhận mật khẩu mới không khớp.")
    @JsonIgnore
    public boolean isPasswordConfirmed() {
        return Objects.equals(newPassword, confirmPassword);
    }

    private static boolean withinByteLimit(String value) {
        return value == null || value.getBytes(StandardCharsets.UTF_8).length <= 72;
    }

    @Override
    public String toString() {
        return "ChangeAdministratorPasswordRequest[redacted]";
    }
}
