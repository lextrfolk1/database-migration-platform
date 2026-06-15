package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.util.MigrationResourceLocator;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class PostgresMigrationStrategy implements DatabaseStrategy {

    private final MigrationResourceLocator resourceLocator;

    public PostgresMigrationStrategy(MigrationResourceLocator resourceLocator) {
        this.resourceLocator = resourceLocator;
    }

    @Override
    public String getDatabaseName() {
        return "postgres";
    }

    @Override
    public List<ValidationIssue> databaseWarnings(MigrationTarget target) {
        List<ValidationIssue> warnings = new ArrayList<>();
        for (String location : target.locations()) {
            resourceLocator.sqlResources(location).forEach(resource -> {
                String filename = resource.getFilename();
                if (filename != null && filename.toLowerCase().contains("index")) {
                    warnings.add(new ValidationIssue(IssueSeverity.WARNING, "POSTGRES_LOCKING_RISK",
                            "Review locking risk for PostgreSQL migration " + filename));
                }
            });
        }
        return warnings;
    }
}
