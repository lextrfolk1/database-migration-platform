package com.lextr.migrationplatform.adapter;

import com.lextr.migrationplatform.model.MigrationTarget;

public interface FlywayAdapter {

    String getDatabaseName();

    FlywayOperations create(MigrationTarget target);
}
