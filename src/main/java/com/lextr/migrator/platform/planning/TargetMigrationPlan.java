package com.lextr.migrator.platform.planning;

import com.lextr.migrator.platform.validation.ValidationIssue;

import java.util.List;

public record TargetMigrationPlan(
        String service,
        String database,
        String environment,
        List<String> migrationLocations,
        List<String> alreadyApplied,
        List<String> pendingVersionedMigrations,
        List<String> repeatableMigrationsToRerun,
        List<String> checksumIssues,
        List<ValidationIssue> validationWarnings,
        List<String> riskWarnings,
        int executionOrder
) {
}
