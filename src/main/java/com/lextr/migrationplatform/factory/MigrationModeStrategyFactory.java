package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.strategy.MigrationModeStrategy;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class MigrationModeStrategyFactory {

    private final List<MigrationModeStrategy> strategies;

    public MigrationModeStrategyFactory(List<MigrationModeStrategy> strategies) {
        this.strategies = List.copyOf(strategies);
    }

    public MigrationModeStrategy getRequired(MigrationRequest request) {
        return strategies.stream()
                .filter(strategy -> strategy.supports(request))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported migration mode"));
    }
}
