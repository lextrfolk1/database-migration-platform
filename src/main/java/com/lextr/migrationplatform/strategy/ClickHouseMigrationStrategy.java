package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ClickHouseMigrationStrategy implements DatabaseStrategy {

    @Override
    public String getDatabaseName() {
        return "clickhouse";
    }

    @Override
    public List<ValidationIssue> databaseWarnings(MigrationTarget target) {
        return List.of(new ValidationIssue(IssueSeverity.WARNING, "CLICKHOUSE_NON_TRANSACTIONAL",
                "ClickHouse DDL is not transactional; rollback may require manual intervention"));
    }
}
