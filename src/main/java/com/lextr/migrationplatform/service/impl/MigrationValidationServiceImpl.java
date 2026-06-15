package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.factory.DatabaseAdapterFactory;
import com.lextr.migrationplatform.factory.ValidationStrategyFactory;
import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.service.MigrationValidationService;
import com.lextr.migrationplatform.strategy.ValidationStrategy;
import com.lextr.migrationplatform.util.MigrationResourceLocator;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class MigrationValidationServiceImpl implements MigrationValidationService {

    private final MigrationResourceLocator resourceLocator;
    private final ValidationStrategyFactory validationStrategyFactory;
    private final DatabaseAdapterFactory databaseAdapterFactory;

    public MigrationValidationServiceImpl(MigrationResourceLocator resourceLocator,
                                          ValidationStrategyFactory validationStrategyFactory,
                                          DatabaseAdapterFactory databaseAdapterFactory) {
        this.resourceLocator = resourceLocator;
        this.validationStrategyFactory = validationStrategyFactory;
        this.databaseAdapterFactory = databaseAdapterFactory;
    }

    @Override
    public List<ValidationIssue> validateTarget(MigrationTarget target, boolean allowRisky) {
        List<ValidationIssue> issues = new ArrayList<>();
        if (!databaseAdapterFactory.supports(target.databaseType())) {
            issues.add(new ValidationIssue(IssueSeverity.ERROR, "UNSUPPORTED_DATABASE", "Unsupported database type: " + target.databaseType()));
            return issues;
        }
        if (target.locations().isEmpty()) {
            issues.add(new ValidationIssue(IssueSeverity.ERROR, "MISSING_LOCATION", "No migration locations configured"));
            return issues;
        }
        if (target.historyTable() == null || target.historyTable().isBlank()) {
            issues.add(new ValidationIssue(IssueSeverity.ERROR, "MISSING_HISTORY_ISOLATION",
                    "Flyway history isolation is not configured for service " + target.service() + " on target " + target.targetName()));
        }

        List<Resource> resources = new ArrayList<>();
        for (String location : target.locations()) {
            List<Resource> found = resourceLocator.sqlResources(location);
            if (found.isEmpty()) {
                issues.add(new ValidationIssue(IssueSeverity.ERROR, "MISSING_LOCATION", "No migration files found at " + location));
                continue;
            }
            resources.addAll(found);
        }

        Set<String> versions = new HashSet<>();
        for (ValidationStrategy validationStrategy : validationStrategyFactory.all()) {
            issues.addAll(validationStrategy.validate(target, resources, versions, allowRisky));
        }
        return issues;
    }

    @Override
    public boolean hasErrors(List<ValidationIssue> issues) {
        return issues.stream().anyMatch(issue -> issue.severity() == IssueSeverity.ERROR);
    }
}
