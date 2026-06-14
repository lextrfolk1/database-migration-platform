package com.lextr.migrator.integrations.databases.postgres;

import com.lextr.migrator.integrations.databases.base.AbstractJdbcDatabaseIntegration;
import com.lextr.migrator.integrations.databases.base.FlywayTargetConfiguration;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.springframework.stereotype.Component;

@Component
public class PostgresDatabaseIntegration extends AbstractJdbcDatabaseIntegration {

    @Override
    public String getDatabaseName() {
        return "postgres";
    }

    @Override
    public FlywayTargetConfiguration getFlywayConfig(MigrationTarget target) {
        return baseConfig(target);
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
