package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.exception.MigrationExecutionException;
import com.lextr.migrationplatform.model.MigrationTarget;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public abstract class AbstractJdbcDatabaseAdapter implements DatabaseAdapter {

    @Override
    public void validateConnection(MigrationTarget target) {
        try {
            if (target.driverClassName() != null && !target.driverClassName().isBlank()) {
                Class.forName(target.driverClassName());
            }
            try (Connection ignored = DriverManager.getConnection(target.url(), target.username(), target.password())) {
                // open/close validates the target
            }
        } catch (ClassNotFoundException | SQLException exception) {
            throw new MigrationExecutionException("Unable to connect to target " + target.targetName() + " (" + target.databaseType() + ") for service " + target.service(), exception);
        }
    }

    protected FlywayTargetConfiguration baseConfiguration(MigrationTarget target) {
        return new FlywayTargetConfiguration(
                target.url(),
                target.username(),
                target.password(),
                target.driverClassName(),
                target.locations(),
                target.schemas(),
                target.baselineOnMigrate(),
                target.baselineVersion(),
                target.cleanDisabled(),
                target.historyTable(),
                target.placeholders()
        );
    }
}
