package com.lextr.migrator.integrations.databases.base;

import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class DatabaseIntegrationRegistry {

    private final Map<String, DatabaseIntegration> integrations;

    public DatabaseIntegrationRegistry(List<DatabaseIntegration> integrations) {
        this.integrations = integrations.stream()
                .collect(Collectors.toMap(integration -> integration.getDatabaseName().toLowerCase(Locale.ROOT), Function.identity()));
    }

    public DatabaseIntegration getRequired(String databaseName) {
        DatabaseIntegration integration = integrations.get(databaseName.toLowerCase(Locale.ROOT));
        if (integration == null) {
            throw new IllegalArgumentException("Unsupported database: " + databaseName);
        }
        return integration;
    }

    public boolean supports(String databaseName) {
        return integrations.containsKey(databaseName.toLowerCase(Locale.ROOT));
    }
}
