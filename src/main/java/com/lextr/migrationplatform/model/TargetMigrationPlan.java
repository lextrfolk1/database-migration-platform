package com.lextr.migrationplatform.model;

import java.util.List;

public record TargetMigrationPlan(
        String service,
        String target,
        String databaseType,
        String environment,
        List<String> migrationLocations,
        String historyTable,
        List<String> alreadyApplied,
        List<String> pendingVersionedMigrations,
        List<String> repeatableMigrationsToRerun,
        List<String> checksumIssues,
        List<ValidationIssue> validationWarnings,
        List<String> riskWarnings,
        int executionOrder
) {
}
