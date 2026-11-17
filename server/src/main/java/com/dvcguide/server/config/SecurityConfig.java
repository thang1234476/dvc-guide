package com.dvcguide.server.config;

import com.dvcguide.server.account.service.SessionService;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.common.response.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Configuration
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService admins(AdministratorRepository repository) {
        return email -> repository.findByEmailIgnoreCase(email)
                .map(admin -> User.withUsername(admin.getEmail())
                        .password(admin.getMatKhauHash())
                        .roles(admin.getVaiTro().name().toUpperCase(java.util.Locale.ROOT))
                        .disabled(!admin.getHoatDong())
                        .build())
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản quản trị."));
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, CorsConfig cors, SessionService sessions,
                                            ObjectMapper json) throws Exception {
        var unauthorized = (org.springframework.security.web.AuthenticationEntryPoint) (request, response, error) ->
                writeError(response, json, 401, "Vui lòng đăng nhập.");
        return http
                .cors(config -> config.configurationSource(cors.corsConfigurationSource()))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(config -> config.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .httpBasic(config -> config.authenticationEntryPoint(unauthorized))
                .exceptionHandling(config -> config.authenticationEntryPoint(unauthorized)
                        .accessDeniedHandler((request, response, error) ->
                                writeError(response, json, 403, "Bạn không có quyền thực hiện thao tác này.")))
                .addFilterBefore(new UserSessionFilter(sessions), BasicAuthenticationFilter.class)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/health", "/swagger-ui.html", "/swagger-ui/**",
                                "/v3/api-docs/**", "/actuator/health", "/actuator/info", "/error").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/register", "/api/v1/auth/login").permitAll()
                        .requestMatchers("/api/v1/admin/**").hasAnyRole("ADMIN", "BIEN_TAP")
                        .requestMatchers(HttpMethod.GET, "/api/v1/procedures", "/api/v1/procedures/*",
                                "/api/v1/procedures/*/agencies", "/api/v1/catalog/**").permitAll()
                        .requestMatchers("/api/v1/auth/logout", "/api/v1/users/me", "/api/v1/users/me/**",
                                "/api/v1/dossiers", "/api/v1/dossiers/**", "/api/v1/feedback",
                                "/api/v1/conversations", "/api/v1/conversations/**").hasRole("USER")
                        .anyRequest().denyAll())
                .build();
    }

    private static void writeError(HttpServletResponse response, ObjectMapper json, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        json.writeValue(response.getOutputStream(), ApiResponse.error(message));
    }

    private static class UserSessionFilter extends OncePerRequestFilter {
        private final SessionService sessions;

        UserSessionFilter(SessionService sessions) {
            this.sessions = sessions;
        }

        @Override
        protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
                throws ServletException, IOException {
            String header = request.getHeader(HttpHeaders.AUTHORIZATION);
            if (header != null && header.regionMatches(true, 0, "Bearer ", 0, 7)) {
                sessions.authenticate(header.substring(7)).ifPresent(principal -> {
                    var context = SecurityContextHolder.createEmptyContext();
                    context.setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                            principal, null, List.of(new SimpleGrantedAuthority("ROLE_USER"))));
                    SecurityContextHolder.setContext(context);
                });
            }
            chain.doFilter(request, response);
        }
    }
}
