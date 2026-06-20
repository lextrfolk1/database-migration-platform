package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.strategy.ValidationStrategy;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ValidationStrategyFactory {

    private final List<ValidationStrategy> strategies;

    public ValidationStrategyFactory(List<ValidationStrategy> strategies) {
        this.strategies = List.copyOf(strategies);
    }

    public List<ValidationStrategy> all() {
        return strategies;
    }
}
