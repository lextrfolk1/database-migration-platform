package com.lextr.migrator.platform.validation;

public record ValidationIssue(
        IssueSeverity severity,
        String code,
        String message
) {
}
