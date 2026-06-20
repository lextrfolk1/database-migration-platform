package com.lextr.migrationplatform.model;

public record ValidationIssue(
        IssueSeverity severity,
        String code,
        String message
) {
}
