package com.dvcguide.server.config;

import com.dvcguide.server.account.service.SessionService;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.admin.security.AdministratorPrincipal;
import com.dvcguide.server.admin.security.AdministratorSessionFilter;
import com.dvcguide.server.common.response.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.RequestAttributeSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextHolderFilter;
import org.springframework.security.web.csrf.CsrfFilter;
import org.springframework.security.web.csrf.HttpSessionCsrfTokenRepository;
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
                .map(AdministratorPrincipal::new)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản quản trị."));
    }

    @Bean
    AuthenticationManager adminAuthenticationManager(UserDetailsService admins, PasswordEncoder passwords) {
        var provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(admins);
        provider.setPasswordEncoder(passwords);
        return new ProviderManager(provider);
    }

    @Bean
    HttpSessionSecurityContextRepository adminSecurityContexts() {
        var repository = new HttpSessionSecurityContextRepository();
        repository.setDisableUrlRewriting(true);
        return repository;
    }

    @Bean
    HttpSessionCsrfTokenRepository adminCsrfTokens() {
        return new HttpSessionCsrfTokenRepository();
    }

    @Bean
    @Order(1)
    SecurityFilterChain adminSecurityFilterChain(HttpSecurity http, CorsConfig cors, ObjectMapper json,
            AdministratorRepository admins, AuthenticationManager adminAuthenticationManager,
            HttpSessionSecurityContextRepository adminSecurityContexts,
            HttpSessionCsrfTokenRepository adminCsrfTokens) throws Exception {
        var unauthorized = (org.springframework.security.web.AuthenticationEntryPoint) (request, response, error) ->
                writeError(response, json, 401, "Vui lòng đăng nhập.");
        return http.securityMatcher("/api/v1/admin/**")
                .authenticationManager(adminAuthenticationManager)
                .cors(config -> config.configurationSource(cors.corsConfigurationSource()))
                .csrf(config -> config.csrfTokenRepository(adminCsrfTokens)
                        .requireCsrfProtectionMatcher(request -> {
                            if (!CsrfFilter.DEFAULT_CSRF_MATCHER.matches(request)) return false;
                            String path = request.getRequestURI().substring(request.getContextPath().length());
                            if (path.equals("/api/v1/admin/auth/login") || path.equals("/api/v1/admin/auth/logout")) {
                                return true;
                            }
                            return request.getSession(false) != null;
                        }))
                .sessionManagement(config -> config.sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED))
                .securityContext(config -> config.securityContextRepository(adminSecurityContexts)
                        .requireExplicitSave(true))
                .requestCache(AbstractHttpConfigurer::disable)
                .logout(AbstractHttpConfigurer::disable)
                .httpBasic(config -> config.authenticationEntryPoint(unauthorized)
                        .securityContextRepository(new RequestAttributeSecurityContextRepository()))
                .exceptionHandling(config -> config.authenticationEntryPoint(unauthorized)
                        .accessDeniedHandler((request, response, error) ->
                                writeError(response, json, 403, "Bạn không có quyền hoặc yêu cầu đã hết hạn. Vui lòng tải lại trang.")))
                .addFilterAfter(new AdministratorSessionFilter(admins), SecurityContextHolderFilter.class)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/admin/auth/csrf", "/api/v1/admin/auth/login",
                                "/api/v1/admin/auth/logout").permitAll()
                        .requestMatchers("/api/v1/admin/accounts", "/api/v1/admin/accounts/**").hasRole("ADMIN")
                        .anyRequest().hasAnyRole("ADMIN", "BIEN_TAP"))
                .build();
    }

    @Bean
    @Order(2)
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
