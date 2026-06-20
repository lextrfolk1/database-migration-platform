package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.RunMode;
import org.springframework.stereotype.Component;

@Component
public class DeltaMigrationStrategy implements MigrationModeStrategy {

    @Override
    public boolean supports(MigrationRequest request) {
        return request.mode() == RunMode.DELTA;
    }

    @Override
    public void beforeMigrate(MigrationRequest request, MigrationTarget target, DatabaseAdapter databaseAdapter, FlywayOperations flywayOperations) {
        // No-op for delta mode.
    }
}
