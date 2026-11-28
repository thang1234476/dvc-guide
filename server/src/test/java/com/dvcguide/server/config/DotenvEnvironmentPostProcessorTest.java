package com.dvcguide.server.config;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.SpringApplication;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.env.SystemEnvironmentPropertySource;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

import static org.assertj.core.api.Assertions.*;

class DotenvEnvironmentPostProcessorTest {
    @TempDir Path folder;

    @Test
    void readsQuotedValuesAndMariaDbConfigurationWithNestedPlaceholders() throws Exception {
        Files.writeString(folder.resolve(".env"), """
                DB_HOST=localhost
                DB_PORT=3306
                DB_NAME=dvc_guide
                DB_URL='jdbc:mariadb://${DB_HOST:-localhost}:${DB_PORT:-3306}/${DB_NAME:-dvc_guide}?timezone=UTC'
                DB_PASSWORD='a password # with $ and = symbols'
                SPRING_JPA_DATABASE_PLATFORM=com.dvcguide.server.config.MariaDbJsonDialect
                """);
        var environment = isolatedEnvironment();
        DotenvEnvironmentPostProcessor.load(environment, folder);
        assertThat(environment.getProperty("DB_URL")).isEqualTo("jdbc:mariadb://localhost:3306/dvc_guide?timezone=UTC");
        assertThat(environment.getProperty("DB_PASSWORD")).isEqualTo("a password # with $ and = symbols");
        assertThat(environment.getProperty("spring.jpa.database-platform"))
                .isEqualTo("com.dvcguide.server.config.MariaDbJsonDialect");
    }

    @Test
    void realEnvironmentOverridesTheFile() throws Exception {
        Files.writeString(folder.resolve(".env"), "SERVER_PORT=8080\n");
        var environment = isolatedEnvironment();
        environment.getPropertySources().replace(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME,
                new SystemEnvironmentPropertySource(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME,
                        Map.of("SERVER_PORT", "9080")));
        DotenvEnvironmentPostProcessor.load(environment, folder);
        assertThat(environment.getProperty("SERVER_PORT")).isEqualTo("9080");
    }

    @Test
    void missingFileIsOptionalAndTestProfileDoesNotReadLocalSecrets() {
        var environment = isolatedEnvironment();
        assertThatCode(() -> DotenvEnvironmentPostProcessor.load(environment, folder)).doesNotThrowAnyException();
        var test = isolatedEnvironment();
        test.setActiveProfiles("test");
        new DotenvEnvironmentPostProcessor().postProcessEnvironment(test, new SpringApplication());
        assertThat(test.getPropertySources().contains(DotenvEnvironmentPostProcessor.SOURCE_NAME)).isFalse();
    }

    @Test
    void prefersServerDirectoryWhenRunningFromRepositoryRoot() throws Exception {
        Path server = Files.createDirectory(folder.resolve("server"));
        Files.writeString(server.resolve("pom.xml"), "<project/>");
        assertThat(DotenvEnvironmentPostProcessor.directory(folder)).isEqualTo(server);
        assertThat(DotenvEnvironmentPostProcessor.directory(server)).isEqualTo(server);
    }

    @Test
    void malformedFileDoesNotExposeSecretContentInErrors() throws Exception {
        Files.writeString(folder.resolve(".env"), "SECRET_PRIVATE_VALUE_WITHOUT_EQUALS\n");
        assertThatThrownBy(() -> DotenvEnvironmentPostProcessor.load(isolatedEnvironment(), folder))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageNotContaining("SECRET_PRIVATE_VALUE")
                .hasNoCause();
    }

    private StandardEnvironment isolatedEnvironment() {
        var environment = new StandardEnvironment();
        environment.getPropertySources().replace(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME,
                new SystemEnvironmentPropertySource(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME, Map.of()));
        return environment;
    }
}
