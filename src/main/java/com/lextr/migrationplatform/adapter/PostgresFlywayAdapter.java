package com.lextr.migrationplatform.adapter;

import org.springframework.stereotype.Component;

@Component
public class PostgresFlywayAdapter extends AbstractFlywayAdapter {

    public PostgresFlywayAdapter(PostgresDatabaseAdapter databaseAdapter) {
        super(databaseAdapter);
    }

    @Override
    public String getDatabaseName() {
        return "postgres";
    }
}
