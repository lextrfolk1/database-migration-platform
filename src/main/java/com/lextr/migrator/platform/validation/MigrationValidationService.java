package com.lextr.migrator.platform.validation;

import com.lextr.migrator.integrations.databases.base.DatabaseIntegrationRegistry;
import com.lextr.migrator.platform.inventory.MigrationResourceLocator;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class MigrationValidationService {

    private final MigrationResourceLocator resourceLocator;
    private final MigrationFilenameParser filenameParser;
    private final SqlRiskScanner riskScanner;
    private final DatabaseIntegrationRegistry registry;

    public MigrationValidationService(MigrationResourceLocator resourceLocator, MigrationFilenameParser filenameParser,
                                      SqlRiskScanner riskScanner, DatabaseIntegrationRegistry registry) {
        this.resourceLocator = resourceLocator;
        this.filenameParser = filenameParser;
        this.riskScanner = riskScanner;
        this.registry = registry;
    }

    public List<ValidationIssue> validateTarget(MigrationTarget target, boolean allowRisky) {
        List<ValidationIssue> issues = new ArrayList<>();
        if (!registry.supports(target.database())) {
            issues.add(new ValidationIssue(IssueSeverity.ERROR, "UNSUPPORTED_DATABASE", "Unsupported database: " + target.database()));
            return issues;
        }
        if (target.locations().isEmpty()) {
            issues.add(new ValidationIssue(IssueSeverity.ERROR, "MISSING_LOCATION", "No migration locations configured"));
            return issues;
        }

        Set<String> versions = new HashSet<>();
        for (String location : target.locations()) {
            List<Resource> resources = resourceLocator.sqlResources(location);
            if (resources.isEmpty()) {
                issues.add(new ValidationIssue(IssueSeverity.ERROR, "MISSING_LOCATION", "No migration files found at " + location));
                continue;
            }
            for (Resource resource : resources) {
                String filename = resource.getFilename();
                try {
                    ParsedMigrationFilename parsed = filenameParser.parse(filename);
                    if (parsed.version() != null && !versions.add(parsed.version())) {
                        issues.add(new ValidationIssue(IssueSeverity.ERROR, "DUPLICATE_VERSION",
                                "Duplicate version " + parsed.version() + " in service " + target.service() + " for database " + target.database()));
                    }
                } catch (IllegalArgumentException exception) {
                    issues.add(new ValidationIssue(IssueSeverity.ERROR, "INVALID_FILENAME", exception.getMessage()));
                }
                List<ValidationIssue> riskIssues = riskScanner.scan(resource);
                if (allowRisky) {
                    issues.addAll(riskIssues.stream()
                            .map(issue -> new ValidationIssue(IssueSeverity.WARNING, issue.code(), issue.message()))
                            .toList());
                } else {
                    issues.addAll(riskIssues.stream()
                            .map(issue -> new ValidationIssue(IssueSeverity.ERROR, "RISKY_SQL", issue.message()))
                            .toList());
                }
            }
        }

        if ("postgres".equals(target.database())) {
            issues.addAll(postgresLockWarnings(target));
        }
        if ("clickhouse".equals(target.database())) {
            issues.add(new ValidationIssue(IssueSeverity.WARNING, "CLICKHOUSE_NON_TRANSACTIONAL",
                    "ClickHouse DDL is not transactional; rollback may require manual intervention"));
        }

        return issues;
    }

    private List<ValidationIssue> postgresLockWarnings(MigrationTarget target) {
        List<ValidationIssue> warnings = new ArrayList<>();
        for (String location : target.locations()) {
            for (Resource resource : resourceLocator.sqlResources(location)) {
                String filename = resource.getFilename();
                if (filename != null && filename.toLowerCase().contains("index")) {
                    warnings.add(new ValidationIssue(IssueSeverity.WARNING, "POSTGRES_LOCKING_RISK",
                            "Review locking risk for PostgreSQL migration " + filename));
                }
            }
        }
        return warnings;
    }

    public boolean hasErrors(List<ValidationIssue> issues) {
        return issues.stream().anyMatch(issue -> issue.severity() == IssueSeverity.ERROR);
    }
}
