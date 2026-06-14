package com.lextr.migrator.integrations.flyway;

import org.flywaydb.core.api.MigrationInfo;

public interface FlywayOperations {

    void validate();

    void migrate();

    void repair();

    void clean();

    boolean isCleanDisabled();

    MigrationInfo[] infoAll();
}
