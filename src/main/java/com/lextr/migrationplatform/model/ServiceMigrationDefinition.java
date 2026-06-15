package com.lextr.migrationplatform.model;

import java.util.List;

public record ServiceMigrationDefinition(
        String serviceName,
        List<ServiceTargetMapping> targetMappings
) {
}
