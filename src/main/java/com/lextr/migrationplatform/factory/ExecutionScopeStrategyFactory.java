package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.strategy.ExecutionScopeStrategy;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ExecutionScopeStrategyFactory {

    private final List<ExecutionScopeStrategy> strategies;

    public ExecutionScopeStrategyFactory(List<ExecutionScopeStrategy> strategies) {
        this.strategies = List.copyOf(strategies);
    }

    public ExecutionScopeStrategy getRequired(MigrationRequest request) {
        return strategies.stream()
                .filter(strategy -> strategy.supports(request))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported execution scope"));
    }
}
