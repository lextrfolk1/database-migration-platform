package com.lextr.migrator.integrations.databases.base;

import com.lextr.migrator.platform.inventory.MigrationTarget;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public abstract class AbstractJdbcDatabaseIntegration implements DatabaseIntegration {

    @Override
    public void validateConnection(MigrationTarget target) {
        try {
            if (target.driverClassName() != null && !target.driverClassName().isBlank()) {
                Class.forName(target.driverClassName());
            }
            try (Connection ignored = DriverManager.getConnection(target.url(), target.username(), target.password())) {
                // Connection open/close validates the target.
            }
        } catch (ClassNotFoundException | SQLException exception) {
            throw new IllegalStateException("Unable to connect to " + target.database() + " for service " + target.service(), exception);
        }
    }

    protected FlywayTargetConfiguration baseConfig(MigrationTarget target) {
        return new FlywayTargetConfiguration(
                target.url(),
                target.username(),
                target.password(),
                target.driverClassName(),
                target.locations(),
                target.schemas(),
                target.baselineOnMigrate(),
                target.cleanDisabled(),
                target.historyTable(),
                target.placeholders()
        );
    }
}
