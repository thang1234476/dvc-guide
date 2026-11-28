package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.AdministratorResponse;
import com.dvcguide.server.admin.dto.ChangeAdministratorPasswordRequest;
import com.dvcguide.server.admin.dto.UpdateAdministratorProfileRequest;
import com.dvcguide.server.admin.security.AdministratorSessionLogout;
import com.dvcguide.server.admin.service.AdministratorService;
import com.dvcguide.server.common.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/v1/admin/me")
@RequiredArgsConstructor
public class AdministratorProfileController {
    private final AdministratorService admins;

    @PutMapping
    public ApiResponse<AdministratorResponse> updateProfile(
            Principal principal, @Valid @RequestBody UpdateAdministratorProfileRequest request) {
        return ApiResponse.success(admins.updateProfile(principal.getName(), request));
    }

    @PostMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(Principal principal, @Valid @RequestBody ChangeAdministratorPasswordRequest input,
                               HttpServletRequest request, HttpServletResponse response) {
        admins.changePassword(principal.getName(), input);
        AdministratorSessionLogout.clear(request, response);
    }
}
