package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.validation.SqlRiskScanner;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DefaultRiskDetectionStrategy implements RiskDetectionStrategy {

    private final SqlRiskScanner riskScanner;

    public DefaultRiskDetectionStrategy(SqlRiskScanner riskScanner) {
        this.riskScanner = riskScanner;
    }

    @Override
    public List<ValidationIssue> detect(Resource resource) {
        return riskScanner.scan(resource);
    }
}
