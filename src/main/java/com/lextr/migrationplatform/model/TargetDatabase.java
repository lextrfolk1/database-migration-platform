package com.lextr.migrationplatform.model;

import java.util.List;
import java.util.Map;

public record TargetDatabase(
        String name,
        String databaseType,
        String environment,
        String url,
        String username,
        String password,
        String driverClassName,
        List<String> defaultSchemas,
        boolean baselineOnMigrate,
        String baselineVersion,
        boolean cleanDisabled,
        String historyTablePrefix,
        Map<String, String> placeholders
) {
}
