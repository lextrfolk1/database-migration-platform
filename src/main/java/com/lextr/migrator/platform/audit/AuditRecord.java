package com.lextr.migrator.platform.audit;

import java.time.Instant;
import java.util.List;

public record AuditRecord(
        String executionId,
        String scope,
        String service,
        String database,
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
