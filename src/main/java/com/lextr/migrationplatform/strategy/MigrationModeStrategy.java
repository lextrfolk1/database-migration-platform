package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;

public interface MigrationModeStrategy {

    boolean supports(MigrationRequest request);

    void beforeMigrate(MigrationRequest request, MigrationTarget target, DatabaseAdapter databaseAdapter, FlywayOperations flywayOperations);
}
