package com.lextr.migrator.integrations.databases.base;

import java.util.List;
import java.util.Map;

public record FlywayTargetConfiguration(
        String url,
        String username,
        String password,
        String driverClassName,
        List<String> locations,
        List<String> schemas,
        boolean baselineOnMigrate,
        boolean cleanDisabled,
        String historyTable,
        Map<String, String> placeholders
) {
}
