package com.lextr.migrationplatform.dto;

import com.lextr.migrationplatform.model.ValidationIssue;

import java.util.List;

public record ExecutionTargetResponse(
        String service,
        String target,
        String databaseType,
        String environment,
        String historyTable,
        String status,
        List<String> executedMigrations,
        String failedMigration,
        String errorMessage,
        List<ValidationIssue> validationIssues
) {
}
