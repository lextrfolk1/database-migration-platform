package com.lextr.migrationplatform.dto;

import java.time.Instant;

public record ErrorResponse(
        Instant timestamp,
        String errorCode,
        String message
) {
}
