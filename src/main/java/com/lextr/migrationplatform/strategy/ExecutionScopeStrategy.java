package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;

import java.util.List;

public interface ExecutionScopeStrategy {

    boolean supports(MigrationRequest request);

    List<MigrationTarget> selectTargets(MigrationRequest request, List<MigrationTarget> availableTargets);
}
