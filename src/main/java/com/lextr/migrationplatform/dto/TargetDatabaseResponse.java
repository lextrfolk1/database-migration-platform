package com.lextr.migrationplatform.dto;

import java.util.List;

public record TargetDatabaseResponse(
        String name,
        String databaseType,
        String environment,
        List<String> schemas,
        boolean cleanDisabled
) {
}
