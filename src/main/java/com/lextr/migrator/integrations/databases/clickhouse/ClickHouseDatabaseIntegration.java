package com.lextr.migrator.integrations.databases.clickhouse;

import com.lextr.migrator.integrations.databases.base.AbstractJdbcDatabaseIntegration;
import com.lextr.migrator.integrations.databases.base.FlywayTargetConfiguration;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.springframework.stereotype.Component;

@Component
public class ClickHouseDatabaseIntegration extends AbstractJdbcDatabaseIntegration {

    @Override
    public String getDatabaseName() {
        return "clickhouse";
    }

    @Override
    public FlywayTargetConfiguration getFlywayConfig(MigrationTarget target) {
        return baseConfig(target);
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
