package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;

import java.util.List;

public interface MigrationExecutionService {

    ExecutionResponse execute(MigrationRequest request, List<MigrationTarget> targets);

    ExecutionResponse repair(MigrationRequest request, List<MigrationTarget> targets);
}
