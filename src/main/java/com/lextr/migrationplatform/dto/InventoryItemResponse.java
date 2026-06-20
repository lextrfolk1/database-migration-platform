package com.lextr.migrationplatform.dto;

import java.util.List;

public record InventoryItemResponse(
        String service,
        String target,
        String databaseType,
        String environment,
        List<String> locations,
        List<String> schemas,
        String historyTable,
        int migrationCount
) {
}
