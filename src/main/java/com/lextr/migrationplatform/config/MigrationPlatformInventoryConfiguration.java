package com.lextr.migrationplatform.config;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public record MigrationPlatformInventoryConfiguration(
        String defaultEnvironment,
        Map<String, EnvironmentConfig> environments,
        Map<String, TargetDatabaseConfig> targets,
        Map<String, ServiceMigrationConfig> services
) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record EnvironmentConfig(
            String description
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TargetDatabaseConfig(
            String type,
            String environment,
            String url,
            String username,
            String password,
            @JsonAlias("password_env")
            String passwordEnv,
            String schema,
            List<String> schemas,
            Boolean baselineOnMigrate,
            String baselineVersion,
            Boolean cleanDisabled,
            String driverClassName,
            String historyTablePrefix,
            Map<String, String> placeholders
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ServiceMigrationConfig(
            List<MigrationLocationConfig> targetMappings
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record MigrationLocationConfig(
            String target,
            List<String> locations,
            String schema,
            List<String> schemas,
            String historyTable,
            Map<String, String> placeholders
    ) {
    }
}
