package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

@Component
@Order(1)
public class ClickHouseSqlValidationStrategy implements ValidationStrategy {

    private final ClickHouseMigrationStrategy databaseStrategy;

    public ClickHouseSqlValidationStrategy(ClickHouseMigrationStrategy databaseStrategy) {
        this.databaseStrategy = databaseStrategy;
    }

    @Override
    public List<ValidationIssue> validate(MigrationTarget target, List<Resource> resources, Set<String> versions, boolean allowRisky) {
        if (!"clickhouse".equals(target.databaseType())) {
            return List.of();
        }
        return databaseStrategy.databaseWarnings(target);
    }
}
