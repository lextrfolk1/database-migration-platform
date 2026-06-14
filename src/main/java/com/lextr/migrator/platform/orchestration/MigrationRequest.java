package com.lextr.migrator.platform.orchestration;

public record MigrationRequest(
        ExecutionScope scope,
        String service,
        String database,
        String environment,
        boolean allDatabases,
        RunMode mode,
        boolean continueOnError,
        boolean allowRisky,
        boolean confirm,
        String requestedBy
) {
}
