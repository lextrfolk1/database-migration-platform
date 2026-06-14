package com.lextr.migrator.platform.validation;

public record ParsedMigrationFilename(
        MigrationKind kind,
        String version,
        String description
) {
}
