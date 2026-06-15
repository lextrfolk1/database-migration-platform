package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

@Component
public class AllDatabasesExecutionStrategy implements ExecutionScopeStrategy {

    @Override
    public boolean supports(MigrationRequest request) {
        return request.scope() == ExecutionScope.ALL_SERVICES && request.allTargets();
    }

    @Override
    public List<MigrationTarget> selectTargets(MigrationRequest request, List<MigrationTarget> availableTargets) {
        List<MigrationTarget> targets = availableTargets.stream()
                .filter(target -> request.environment() == null || request.environment().isBlank() || target.environment().equals(request.environment()))
                .sorted(Comparator.comparing(MigrationTarget::service).thenComparing(MigrationTarget::targetName))
                .toList();
        if (targets.isEmpty()) {
            throw new ServiceNotFoundException("No migration targets found for the requested scope");
        }
        return targets;
    }
}
