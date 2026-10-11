package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.TargetMigrationPlan;
import com.lextr.migrationplatform.model.ValidationIssue;

import java.util.List;

public interface MigrationPlanService {

    MigrationPlan createPlan(List<MigrationTarget> targets, boolean allowRisky);

    TargetMigrationPlan createExecutionPlan(MigrationTarget target, FlywayOperations flyway, List<ValidationIssue> validationIssues);
}
