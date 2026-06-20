package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.model.MigrationTarget;
import org.springframework.stereotype.Component;

@Component
public class PostgresDatabaseAdapter extends AbstractJdbcDatabaseAdapter {

    @Override
    public String getDatabaseName() {
        return "postgres";
    }

    @Override
    public FlywayTargetConfiguration getFlywayTargetConfiguration(MigrationTarget target) {
        return baseConfiguration(target);
    }

    @Override
    public boolean supportsTransactions() {
        return true;
    }

    @Override
    public boolean supportsClean() {
        return true;
    }

    @Override
    public String getDialectName() {
        return "PostgreSQL";
    }
}
