package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ParsedMigrationFilename;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.validation.MigrationFilenameParser;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Component
@Order(0)
public class CommonSqlValidationStrategy implements ValidationStrategy {

    private final MigrationFilenameParser filenameParser;
    private final RiskDetectionStrategy strictRiskDetectionStrategy;
    private final RiskDetectionStrategy defaultRiskDetectionStrategy;

    public CommonSqlValidationStrategy(MigrationFilenameParser filenameParser,
                                       StrictRiskDetectionStrategy strictRiskDetectionStrategy,
                                       DefaultRiskDetectionStrategy defaultRiskDetectionStrategy) {
        this.filenameParser = filenameParser;
        this.strictRiskDetectionStrategy = strictRiskDetectionStrategy;
        this.defaultRiskDetectionStrategy = defaultRiskDetectionStrategy;
    }

    @Override
    public List<ValidationIssue> validate(MigrationTarget target, List<Resource> resources, Set<String> versions, boolean allowRisky) {
        List<ValidationIssue> issues = new ArrayList<>();
        for (Resource resource : resources) {
            String filename = resource.getFilename();
            try {
                ParsedMigrationFilename parsed = filenameParser.parse(filename);
                if (parsed.version() != null && !versions.add(parsed.version())) {
                    issues.add(new ValidationIssue(IssueSeverity.ERROR, "DUPLICATE_VERSION",
                            "Duplicate version " + parsed.version() + " in service " + target.service() + " for target " + target.targetName()));
                }
            } catch (IllegalArgumentException exception) {
                issues.add(new ValidationIssue(IssueSeverity.ERROR, "INVALID_FILENAME", exception.getMessage()));
            }

            List<ValidationIssue> riskIssues = allowRisky
                    ? defaultRiskDetectionStrategy.detect(resource)
                    : strictRiskDetectionStrategy.detect(resource);
            issues.addAll(riskIssues);
        }
        return issues;
    }
}
