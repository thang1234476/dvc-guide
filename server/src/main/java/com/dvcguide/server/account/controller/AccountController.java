package com.dvcguide.server.account.controller;

import com.dvcguide.server.account.service.AccountService;
import com.dvcguide.server.account.service.AccountService.AuthResult;
import com.dvcguide.server.account.service.AccountService.Profile;
import com.dvcguide.server.account.service.SessionService;
import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class AccountController {
    private final AccountService accounts;
    private final SessionService sessions;

    @PostMapping("/auth/register")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AuthResult> register(@Valid @RequestBody AccountService.Registration request) {
        return ApiResponse.success(accounts.register(request));
    }

    @PostMapping("/auth/login")
    public ApiResponse<AuthResult> login(@Valid @RequestBody AccountService.Credentials request) {
        return ApiResponse.success(accounts.login(request));
    }

    @PostMapping("/auth/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@AuthenticationPrincipal UserSession principal) {
        sessions.revoke(principal);
    }

    @GetMapping("/users/me")
    public ApiResponse<Profile> profile(@AuthenticationPrincipal UserSession principal) {
        return ApiResponse.success(accounts.profile(principal.userId()));
    }

    @PutMapping("/users/me")
    public ApiResponse<Profile> update(@AuthenticationPrincipal UserSession principal,
                                       @Valid @RequestBody AccountService.Settings request) {
        return ApiResponse.success(accounts.update(principal.userId(), request));
    }

    @DeleteMapping("/users/me/data")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void clearData(@AuthenticationPrincipal UserSession principal) {
        accounts.clearPersonalData(principal.userId());
    }

    @DeleteMapping("/users/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal UserSession principal) {
        accounts.delete(principal.userId());
    }
}
