package com.lextr.migrationplatform.entity;

import java.time.Instant;
import java.util.List;

public record MigrationAuditEntity(
        String executionId,
        String scope,
        String service,
        String target,
        String databaseType,
        String environment,
        String mode,
        String requestedBy,
        Instant startedAt,
        Instant completedAt,
        String status,
        List<String> executedMigrations,
        String failedMigration,
        String errorMessage,
        long durationMs,
        boolean riskOverrideUsed
) {
}
