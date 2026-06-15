package com.lextr.migrationplatform.dto;

import java.util.List;

public record ServiceDetailsResponse(
        String service,
        List<String> targets
) {
}
