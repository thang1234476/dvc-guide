package com.dvcguide.server.admin.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;

public final class AdministratorSessionLogout {
    private AdministratorSessionLogout() {}

    public static void clear(HttpServletRequest request, HttpServletResponse response) {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        new SecurityContextLogoutHandler().logout(request, response, authentication);
        var cookie = ResponseCookie.from("DVC_ADMIN_SESSION", "")
                .path("/api/v1/admin").httpOnly(true).sameSite("Lax")
                .secure(request.isSecure()).maxAge(0).build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }
}
