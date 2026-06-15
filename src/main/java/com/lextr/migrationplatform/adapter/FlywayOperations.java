package com.lextr.migrationplatform.adapter;

import org.flywaydb.core.api.MigrationInfo;

public interface FlywayOperations {

    void validate();

    void migrate();

    void repair();

    void clean();

    boolean isCleanDisabled();

    MigrationInfo[] infoAll();
}
