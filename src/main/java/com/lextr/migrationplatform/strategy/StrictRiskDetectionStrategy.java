package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.ValidationIssue;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class StrictRiskDetectionStrategy implements RiskDetectionStrategy {

    private final DefaultRiskDetectionStrategy delegate;

    public StrictRiskDetectionStrategy(DefaultRiskDetectionStrategy delegate) {
        this.delegate = delegate;
    }

    @Override
    public List<ValidationIssue> detect(org.springframework.core.io.Resource resource) {
        return delegate.detect(resource).stream()
                .map(issue -> new ValidationIssue(IssueSeverity.ERROR, "RISKY_SQL", issue.message()))
                .toList();
    }
}
