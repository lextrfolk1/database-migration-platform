package com.lextr.migrator.platform.orchestration;

import com.lextr.migrator.platform.validation.ValidationIssue;

import java.util.List;

public record ExecutionTargetResult(
        String service,
        String database,
        String environment,
        String status,
        List<String> executedMigrations,
        String failedMigration,
        String errorMessage,
        List<ValidationIssue> validationIssues
) {
}
