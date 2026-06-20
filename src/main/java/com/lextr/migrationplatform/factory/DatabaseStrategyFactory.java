package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.exception.UnsupportedDatabaseException;
import com.lextr.migrationplatform.strategy.DatabaseStrategy;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class DatabaseStrategyFactory {

    private final Map<String, DatabaseStrategy> strategies;

    public DatabaseStrategyFactory(List<DatabaseStrategy> strategies) {
        this.strategies = strategies.stream()
                .collect(Collectors.toMap(strategy -> strategy.getDatabaseName().toLowerCase(Locale.ROOT), Function.identity()));
    }

    public DatabaseStrategy getRequired(String databaseName) {
        DatabaseStrategy strategy = strategies.get(databaseName.toLowerCase(Locale.ROOT));
        if (strategy == null) {
            throw new UnsupportedDatabaseException("Unsupported database: " + databaseName);
        }
        return strategy;
    }
}
