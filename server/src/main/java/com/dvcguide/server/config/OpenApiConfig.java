package com.dvcguide.server.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI / Swagger UI configuration.
 * Access at: http://localhost:8080/swagger-ui.html
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI dvcGuideOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("DVC Guide API")
                        .description("API Server for DVC Guide – AI-powered administrative procedure assistant")
                        .version("0.1.0")
                        .contact(new Contact()
                                .name("DVC Guide Team")
                                .email("dev@dvcguide.vn"))
                        .license(new License()
                                .name("Private")))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Local Development"),
                        new Server().url("https://api.dvcguide.vn").description("Production")
                ));
    }
}
