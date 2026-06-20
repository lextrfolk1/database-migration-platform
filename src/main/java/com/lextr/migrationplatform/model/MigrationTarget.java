package com.lextr.migrationplatform.model;

import java.util.List;
import java.util.Map;

public record MigrationTarget(
        String environment,
        String service,
        String targetName,
        String databaseType,
        String url,
        String username,
        String password,
        String driverClassName,
        List<String> locations,
        List<String> schemas,
        boolean baselineOnMigrate,
        String baselineVersion,
        boolean cleanDisabled,
        String historyTable,
        Map<String, String> placeholders
) {
}
