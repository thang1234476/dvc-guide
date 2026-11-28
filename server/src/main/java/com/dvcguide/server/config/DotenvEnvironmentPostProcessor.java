package com.dvcguide.server.config;

import io.github.cdimascio.dotenv.Dotenv;
import io.github.cdimascio.dotenv.DotenvException;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.Profiles;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.env.SystemEnvironmentPropertySource;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

public class DotenvEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {
    static final String SOURCE_NAME = "dotenv-systemEnvironment";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (environment.acceptsProfiles(Profiles.of("test"))) return;
        load(environment, directory(Path.of("").toAbsolutePath()));
    }

    static Path directory(Path workingDirectory) {
        Path server = workingDirectory.resolve("server");
        return Files.isRegularFile(server.resolve("pom.xml")) ? server : workingDirectory;
    }

    static void load(ConfigurableEnvironment environment, Path directory) {
        Map<String, Object> values = new LinkedHashMap<>();
        try {
            Dotenv.configure().directory(directory.toString()).ignoreIfMissing().load()
                    .entries(Dotenv.Filter.DECLARED_IN_ENV_FILE)
                    .forEach(entry -> values.put(entry.getKey(), unquote(entry.getValue())));
        } catch (DotenvException exception) {
            // Parser errors can contain secret values from the original line.
            throw new IllegalStateException("Không đọc được file .env. Hãy kiểm tra cú pháp KEY=value và dấu nháy.");
        }
        environment.getPropertySources().addAfter(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME,
                new SystemEnvironmentPropertySource(SOURCE_NAME, values));
    }

    private static String unquote(String value) {
        if (value.length() >= 2 && value.startsWith("'") && value.endsWith("'")) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }

    @Override
    public int getOrder() {
        return ConfigDataEnvironmentPostProcessor.ORDER + 1;
    }
}
