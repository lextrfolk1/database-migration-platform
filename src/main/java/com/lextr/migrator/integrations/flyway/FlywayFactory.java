package com.lextr.migrator.integrations.flyway;

import com.lextr.migrator.integrations.databases.base.DatabaseIntegration;
import com.lextr.migrator.integrations.databases.base.DatabaseIntegrationRegistry;
import com.lextr.migrator.integrations.databases.base.FlywayTargetConfiguration;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import org.springframework.stereotype.Component;

@Component
public class FlywayFactory {

    private final DatabaseIntegrationRegistry registry;

    public FlywayFactory(DatabaseIntegrationRegistry registry) {
        this.registry = registry;
    }

    public FlywayOperations create(MigrationTarget target) {
        DatabaseIntegration integration = registry.getRequired(target.database());
        FlywayTargetConfiguration targetConfiguration = integration.getFlywayConfig(target);

        FluentConfiguration configuration = Flyway.configure()
                .dataSource(targetConfiguration.url(), targetConfiguration.username(), targetConfiguration.password())
                .baselineOnMigrate(targetConfiguration.baselineOnMigrate())
                .cleanDisabled(targetConfiguration.cleanDisabled())
                .locations(targetConfiguration.locations().toArray(String[]::new));

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
