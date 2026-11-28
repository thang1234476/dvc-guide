package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.AdministratorLoginRequest;
import com.dvcguide.server.admin.security.AdministratorSessionLogout;
import com.dvcguide.server.admin.service.AdminProcedureService;
import com.dvcguide.server.common.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.session.ChangeSessionIdAuthenticationStrategy;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.csrf.CsrfAuthenticationStrategy;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.web.csrf.HttpSessionCsrfTokenRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/admin/auth")
@RequiredArgsConstructor
public class AdministratorAuthController {
    private final AuthenticationManager adminAuthenticationManager;
    private final HttpSessionSecurityContextRepository adminSecurityContexts;
    private final HttpSessionCsrfTokenRepository adminCsrfTokens;
    private final AdminProcedureService admins;

    public record CsrfResponse(String headerName, String token) {}

    @GetMapping("/csrf")
    public ApiResponse<CsrfResponse> csrf(CsrfToken token) {
        return ApiResponse.success(new CsrfResponse(token.getHeaderName(), token.getToken()));
    }

    @PostMapping("/login")
    public ApiResponse<AdminProcedureService.AdminProfile> login(
            @Valid @RequestBody AdministratorLoginRequest input,
            HttpServletRequest request, HttpServletResponse response) {
        try {
            var authentication = adminAuthenticationManager.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(input.email(), input.password()));
            new ChangeSessionIdAuthenticationStrategy().onAuthentication(authentication, request, response);
            new CsrfAuthenticationStrategy(adminCsrfTokens).onAuthentication(authentication, request, response);
            var context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(authentication);
            SecurityContextHolder.setContext(context);
            adminSecurityContexts.saveContext(context, request, response);
            return ApiResponse.success(admins.profile(authentication.getName()));
        } catch (AuthenticationException ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng.");
        }
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(HttpServletRequest request, HttpServletResponse response) {
        AdministratorSessionLogout.clear(request, response);
    }
}
