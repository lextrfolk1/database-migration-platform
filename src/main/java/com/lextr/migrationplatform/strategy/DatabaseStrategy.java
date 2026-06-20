package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;

import java.util.List;

public interface DatabaseStrategy {

    String getDatabaseName();

    List<ValidationIssue> databaseWarnings(MigrationTarget target);
}
