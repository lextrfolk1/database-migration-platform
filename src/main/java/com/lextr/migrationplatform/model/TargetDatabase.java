package com.lextr.migrationplatform.model;

import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

public record TargetDatabase(
        String name,
        String databaseType,
        String environment,
        String url,
        String username,
        Supplier<String> passwordSupplier,
        String driverClassName,
        List<String> defaultSchemas,
        boolean baselineOnMigrate,
        String baselineVersion,
        boolean cleanDisabled,
        String historyTablePrefix,
        Map<String, String> placeholders
) {

    public TargetDatabase(String name, String databaseType, String environment, String url, String username,
                          String password, String driverClassName, List<String> defaultSchemas,
                          boolean baselineOnMigrate, String baselineVersion, boolean cleanDisabled,
                          String historyTablePrefix, Map<String, String> placeholders) {
        this(name, databaseType, environment, url, username, () -> password,
             driverClassName, defaultSchemas, baselineOnMigrate, baselineVersion,
             cleanDisabled, historyTablePrefix, placeholders);
    }

    public String password() {
        return passwordSupplier != null ? passwordSupplier.get() : null;
    }
}
