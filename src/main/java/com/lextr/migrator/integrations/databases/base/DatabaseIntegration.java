package com.lextr.migrator.integrations.databases.base;

import com.lextr.migrator.platform.inventory.MigrationTarget;

public interface DatabaseIntegration {

    String getDatabaseName();

    void validateConnection(MigrationTarget target);

    FlywayTargetConfiguration getFlywayConfig(MigrationTarget target);

    boolean supportsTransactions();

    boolean supportsClean();

    String getDialectName();
}
