package com.lextr.migrator.platform.orchestration;

import java.util.List;

public record ExecutionResponse(
        String executionId,
        String scope,
        String status,
        List<ExecutionTargetResult> results
) {
}
