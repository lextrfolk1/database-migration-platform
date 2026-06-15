package com.lextr.migrationplatform.dto;

import java.util.List;

public record ExecutionResponse(
        String executionId,
        String scope,
        String status,
        List<ExecutionTargetResponse> results
) {
}
