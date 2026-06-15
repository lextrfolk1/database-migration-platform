package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.exception.MigrationExecutionException;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.RunMode;
import org.springframework.stereotype.Component;

import java.util.Locale;

@Component
public class FreshRebuildStrategy implements MigrationModeStrategy {

    private final MigrationPlatformProperties properties;

    public FreshRebuildStrategy(MigrationPlatformProperties properties) {
        this.properties = properties;
    }

    @Override
    public boolean supports(MigrationRequest request) {
        return request.mode() == RunMode.REBUILD;
    }

    @Override
    public void beforeMigrate(MigrationRequest request, MigrationTarget target, DatabaseAdapter databaseAdapter, FlywayOperations flywayOperations) {
        String environmentName = target.environment().toLowerCase(Locale.ROOT);
        if (!request.confirm()) {
            throw new MigrationExecutionException("Rebuild requires explicit confirmation");
        }
        if (!databaseAdapter.supportsClean()) {
            throw new MigrationExecutionException("Rebuild is not supported for target " + target.targetName() + " (" + target.databaseType() + ")");
        }
        if (target.cleanDisabled() || flywayOperations.isCleanDisabled()) {
            throw new MigrationExecutionException("Flyway clean is disabled for " + target.service() + "/" + target.targetName());
        }
        if ((environmentName.equals("prod") || environmentName.equals("production")) && !properties.isAllowProductionRebuild()) {
            throw new MigrationExecutionException("Production rebuild is blocked by configuration");
        }
        flywayOperations.clean();
    }
}
