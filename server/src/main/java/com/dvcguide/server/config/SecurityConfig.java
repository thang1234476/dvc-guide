package com.dvcguide.server.config;

import com.dvcguide.server.config.CorsConfig;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Spring Security configuration.
 * <p>
 * CURRENT STATE: Security is configured in permissive mode for development.
 * All endpoints are publicly accessible. CSRF is disabled for REST API.
 * Session is stateless.
 * <p>
 * FUTURE: Add JWT authentication by:
 * 1. Adding JwtAuthenticationFilter before UsernamePasswordAuthenticationFilter
 * 2. Restricting .requestMatchers to specific public paths
 * 3. Requiring authentication for all other paths
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final CorsConfig corsConfig;

    public SecurityConfig(CorsConfig corsConfig) {
        this.corsConfig = corsConfig;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Apply CORS configuration
            .cors(cors -> cors.configurationSource(corsConfig.corsConfigurationSource()))

            // Disable CSRF – REST APIs use tokens, not sessions
            .csrf(AbstractHttpConfigurer::disable)

            // Stateless session – no HttpSession
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // Authorization rules
            // TODO: Restrict when JWT is implemented
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/api/v1/health",
                    "/swagger-ui.html",
                    "/swagger-ui/**",
                    "/v3/api-docs/**",
                    "/actuator/**"
                ).permitAll()
                .anyRequest().permitAll()  // TODO: Change to .authenticated() when JWT is added
            );

        return http.build();
    }
}
