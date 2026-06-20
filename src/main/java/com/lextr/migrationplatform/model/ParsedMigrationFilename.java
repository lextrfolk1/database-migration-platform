package com.lextr.migrationplatform.model;

public record ParsedMigrationFilename(
        MigrationKind kind,
        String version,
        String description
) {
}
