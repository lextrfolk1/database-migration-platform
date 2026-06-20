package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationTarget;

import java.util.List;

public interface MigrationPlanService {

    MigrationPlan createPlan(List<MigrationTarget> targets, boolean allowRisky);
}
