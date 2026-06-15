package com.lextr.migrationplatform.model;

public record MigrationRequest(
        ExecutionScope scope,
        String service,
        String target,
        String databaseType,
        String environment,
        boolean allTargets,
        RunMode mode,
        boolean continueOnError,
        boolean allowRisky,
        boolean confirm,
        String requestedBy
) {
}
