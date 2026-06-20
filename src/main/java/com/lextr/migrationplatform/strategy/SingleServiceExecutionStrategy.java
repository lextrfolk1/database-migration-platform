package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SingleServiceExecutionStrategy implements ExecutionScopeStrategy {

    @Override
    public boolean supports(MigrationRequest request) {
        return request.scope() == ExecutionScope.SERVICE;
    }

    @Override
    public List<MigrationTarget> selectTargets(MigrationRequest request, List<MigrationTarget> availableTargets) {
        if (request.service() == null || request.service().isBlank()) {
            throw new ServiceNotFoundException("Service name is required for service scope");
        }
        if ((request.target() == null || request.target().isBlank())
                && (request.databaseType() == null || request.databaseType().isBlank())) {
            throw new ServiceNotFoundException("Target name is required for service scope; database type is only a compatibility fallback");
        }

        List<MigrationTarget> matches = availableTargets.stream()
                .filter(target -> request.environment() == null || request.environment().isBlank() || target.environment().equals(request.environment()))
                .filter(target -> target.service().equals(request.service()))
                .filter(target -> matchesTarget(request, target))
                .toList();

        if (matches.isEmpty()) {
            throw new ServiceNotFoundException("Service " + request.service() + " is not mapped to the requested target/database");
        }
        if (matches.size() > 1) {
            throw new ServiceNotFoundException("Service " + request.service() + " maps to multiple targets for the supplied database type; use --target");
        }
        return matches;
    }

    private boolean matchesTarget(MigrationRequest request, MigrationTarget target) {
        if (request.target() != null && !request.target().isBlank()) {
            return target.targetName().equals(request.target());
        }
        return target.databaseType().equals(request.databaseType());
    }
}
