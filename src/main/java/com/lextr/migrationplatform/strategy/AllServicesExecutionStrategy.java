package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

@Component
public class AllServicesExecutionStrategy implements ExecutionScopeStrategy {

    @Override
    public boolean supports(MigrationRequest request) {
        return request.scope() == ExecutionScope.ALL_SERVICES && !request.allTargets();
    }

    @Override
    public List<MigrationTarget> selectTargets(MigrationRequest request, List<MigrationTarget> availableTargets) {
        if ((request.target() == null || request.target().isBlank())
                && (request.databaseType() == null || request.databaseType().isBlank())) {
            throw new ServiceNotFoundException("Target name is required unless --all-targets is set");
        }
        List<MigrationTarget> targets = availableTargets.stream()
                .filter(target -> request.environment() == null || request.environment().isBlank() || target.environment().equals(request.environment()))
                .filter(target -> matchesTarget(request, target))
                .sorted(Comparator.comparing(MigrationTarget::service).thenComparing(MigrationTarget::targetName))
                .toList();
        if (targets.isEmpty()) {
            throw new ServiceNotFoundException("No migration targets found for the requested scope");
        }
        if ((request.target() == null || request.target().isBlank()) && hasMultipleTargetsForDatabaseType(targets)) {
            throw new ServiceNotFoundException("Multiple targets share database type " + request.databaseType() + "; use --target or --all-targets");
        }
        return targets;
    }

    private boolean matchesTarget(MigrationRequest request, MigrationTarget target) {
        if (request.target() != null && !request.target().isBlank()) {
            return target.targetName().equals(request.target());
        }
        return target.databaseType().equals(request.databaseType());
    }

    private boolean hasMultipleTargetsForDatabaseType(List<MigrationTarget> targets) {
        return targets.stream().map(MigrationTarget::targetName).distinct().count() > 1;
    }
}
