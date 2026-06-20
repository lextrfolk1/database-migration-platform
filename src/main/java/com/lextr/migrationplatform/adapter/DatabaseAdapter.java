package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.model.MigrationTarget;

public interface DatabaseAdapter {

    String getDatabaseName();

    void validateConnection(MigrationTarget target);

    FlywayTargetConfiguration getFlywayTargetConfiguration(MigrationTarget target);

    boolean supportsTransactions();

    boolean supportsClean();

    String getDialectName();
}
