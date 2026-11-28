package com.dvcguide.server.admin.security;

import com.dvcguide.server.admin.repository.AdministratorRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public final class AdministratorSessionFilter extends OncePerRequestFilter {
    private final AdministratorRepository admins;

    public AdministratorSessionFilter(AdministratorRepository admins) {
        this.admins = admins;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof AdministratorPrincipal principal
                && admins.findById(principal.administratorId()).filter(principal::isCurrent).isEmpty()) {
            AdministratorSessionLogout.clear(request, response);
        }
        chain.doFilter(request, response);
    }
}
