package com.lextr.migrationplatform.model;

import java.util.List;
import java.util.Map;

public record ServiceTargetMapping(
        String targetName,
        List<String> locations,
        List<String> schemas,
        String historyTable,
        Map<String, String> placeholders
) {
}
