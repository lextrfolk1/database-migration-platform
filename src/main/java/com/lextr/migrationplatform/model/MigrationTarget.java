package com.lextr.migrationplatform.model;

import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

public record MigrationTarget(
        String environment,
        String service,
        String targetName,
        String databaseType,
        String url,
        String username,
        Supplier<String> passwordSupplier,
        String driverClassName,
        List<String> locations,
        List<String> schemas,
        boolean baselineOnMigrate,
        String baselineVersion,
        boolean cleanDisabled,
        String historyTable,
        Map<String, String> placeholders
) {

    public MigrationTarget(String environment, String service, String targetName, String databaseType,
                           String url, String username, String password, String driverClassName,
                           List<String> locations, List<String> schemas, boolean baselineOnMigrate,
                           String baselineVersion, boolean cleanDisabled, String historyTable,
                           Map<String, String> placeholders) {
        this(environment, service, targetName, databaseType, url, username, () -> password,
             driverClassName, locations, schemas, baselineOnMigrate, baselineVersion,
             cleanDisabled, historyTable, placeholders);
    }

    public String password() {
        return passwordSupplier != null ? passwordSupplier.get() : null;
    }
}
