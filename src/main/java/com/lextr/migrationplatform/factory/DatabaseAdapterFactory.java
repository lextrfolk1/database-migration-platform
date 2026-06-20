package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.exception.UnsupportedDatabaseException;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class DatabaseAdapterFactory {

    private final Map<String, DatabaseAdapter> adapters;

    public DatabaseAdapterFactory(List<DatabaseAdapter> adapters) {
        this.adapters = adapters.stream()
                .collect(Collectors.toMap(adapter -> adapter.getDatabaseName().toLowerCase(Locale.ROOT), Function.identity()));
    }

    public DatabaseAdapter getRequired(String databaseName) {
        DatabaseAdapter adapter = adapters.get(databaseName.toLowerCase(Locale.ROOT));
        if (adapter == null) {
            throw new UnsupportedDatabaseException("Unsupported database: " + databaseName);
        }
        return adapter;
    }

    public boolean supports(String databaseName) {
        return adapters.containsKey(databaseName.toLowerCase(Locale.ROOT));
    }
}
