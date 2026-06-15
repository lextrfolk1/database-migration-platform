package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.model.MigrationTarget;
import org.springframework.stereotype.Component;

@Component
public class ClickHouseDatabaseAdapter extends AbstractJdbcDatabaseAdapter {

    @Override
    public String getDatabaseName() {
        return "clickhouse";
    }

    @Override
    public FlywayTargetConfiguration getFlywayTargetConfiguration(MigrationTarget target) {
        return baseConfiguration(target);
    }

    @Override
    public boolean supportsTransactions() {
        return false;
    }

    @Override
    public boolean supportsClean() {
        return false;
    }

    @Override
    public String getDialectName() {
        return "ClickHouse";
    }
}
