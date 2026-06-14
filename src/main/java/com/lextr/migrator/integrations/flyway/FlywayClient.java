package com.lextr.migrator.integrations.flyway;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;

public class FlywayClient implements FlywayOperations {

    private final Flyway flyway;

    public FlywayClient(Flyway flyway) {
        this.flyway = flyway;
    }

    @Override
    public void validate() {
        flyway.validate();
    }

    @Override
    public void migrate() {
        flyway.migrate();
    }

    @Override
    public void repair() {
        flyway.repair();
    }

    @Override
    public void clean() {
        flyway.clean();
    }

    @Override
    public boolean isCleanDisabled() {
        return flyway.getConfiguration().isCleanDisabled();
    }

    @Override
    public MigrationInfo[] infoAll() {
        return flyway.info().all();
    }
}
