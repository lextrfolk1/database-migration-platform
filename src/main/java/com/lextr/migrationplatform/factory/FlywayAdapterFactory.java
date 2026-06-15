package com.lextr.migrationplatform.factory;

import com.lextr.migrationplatform.adapter.FlywayAdapter;
import com.lextr.migrationplatform.exception.UnsupportedDatabaseException;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class FlywayAdapterFactory {

    private final Map<String, FlywayAdapter> adapters;

    public FlywayAdapterFactory(List<FlywayAdapter> adapters) {
        this.adapters = adapters.stream()
                .collect(Collectors.toMap(adapter -> adapter.getDatabaseName().toLowerCase(Locale.ROOT), Function.identity()));
    }

    public FlywayAdapter getRequired(String databaseName) {
        FlywayAdapter adapter = adapters.get(databaseName.toLowerCase(Locale.ROOT));
        if (adapter == null) {
            throw new UnsupportedDatabaseException("Unsupported database: " + databaseName);
        }
        return adapter;
    }
}
