package com.lextr.migrator.platform.inventory;

import java.util.List;
import java.util.Map;

public record MigrationTarget(
        String environment,
        String service,
        String database,
        String url,
        String username,
        String password,
        String driverClassName,
        List<String> locations,
        List<String> schemas,
        boolean baselineOnMigrate,
        boolean cleanDisabled,
        String historyTable,
        Map<String, String> placeholders,
        boolean legacyCompatible
) {
}
