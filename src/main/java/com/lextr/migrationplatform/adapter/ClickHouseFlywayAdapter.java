package com.lextr.migrationplatform.adapter;

import org.springframework.stereotype.Component;

@Component
public class ClickHouseFlywayAdapter extends AbstractFlywayAdapter {

    public ClickHouseFlywayAdapter(ClickHouseDatabaseAdapter databaseAdapter) {
        super(databaseAdapter);
    }

    @Override
    public String getDatabaseName() {
        return "clickhouse";
    }
}
