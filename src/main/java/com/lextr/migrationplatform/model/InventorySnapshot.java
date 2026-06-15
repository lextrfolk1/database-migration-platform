package com.lextr.migrationplatform.model;

import java.util.Map;

public record InventorySnapshot(
        String defaultEnvironment,
        Map<String, TargetDatabase> targets,
        Map<String, ServiceMigrationDefinition> services
) {
}
