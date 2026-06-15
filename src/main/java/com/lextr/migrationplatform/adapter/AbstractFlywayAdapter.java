package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.model.MigrationTarget;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.flywaydb.core.api.configuration.FluentConfiguration;

public abstract class AbstractFlywayAdapter implements FlywayAdapter {

    private final DatabaseAdapter databaseAdapter;

    protected AbstractFlywayAdapter(DatabaseAdapter databaseAdapter) {
        this.databaseAdapter = databaseAdapter;
    }

    @Override
    public FlywayOperations create(MigrationTarget target) {
        FlywayTargetConfiguration targetConfiguration = databaseAdapter.getFlywayTargetConfiguration(target);
        FluentConfiguration configuration = Flyway.configure()
                .dataSource(targetConfiguration.url(), targetConfiguration.username(), targetConfiguration.password())
                .baselineOnMigrate(targetConfiguration.baselineOnMigrate())
                .cleanDisabled(targetConfiguration.cleanDisabled())
                .locations(targetConfiguration.locations().toArray(String[]::new));

        if (targetConfiguration.baselineVersion() != null && !targetConfiguration.baselineVersion().isBlank()) {
            configuration.baselineVersion(MigrationVersion.fromVersion(targetConfiguration.baselineVersion()));
        }

        if (targetConfiguration.driverClassName() != null && !targetConfiguration.driverClassName().isBlank()) {
            configuration.driver(targetConfiguration.driverClassName());
        }
        if (!targetConfiguration.schemas().isEmpty()) {
            configuration.schemas(targetConfiguration.schemas().toArray(String[]::new));
        }
        if (targetConfiguration.historyTable() != null && !targetConfiguration.historyTable().isBlank()) {
            configuration.table(targetConfiguration.historyTable());
        }
        if (!targetConfiguration.placeholders().isEmpty()) {
            configuration.placeholders(targetConfiguration.placeholders());
        }

        return new FlywayClient(configuration.load());
    }
}
