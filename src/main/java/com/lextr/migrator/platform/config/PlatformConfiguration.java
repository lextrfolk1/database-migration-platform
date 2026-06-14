package com.lextr.migrator.platform.config;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PlatformConfiguration(
        String defaultEnvironment,
        Map<String, EnvironmentDefinition> environments
) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record EnvironmentDefinition(
            Map<String, Map<String, DatabaseDefinition>> services
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record DatabaseDefinition(
            String url,
            String username,
            String password,
            String passwordEnv,
            List<String> locations,
            List<String> schemas,
            Boolean baselineOnMigrate,
            Boolean cleanDisabled,
            String driverClassName,
            String historyTable,
            Map<String, String> placeholders
    ) {
    }
}
