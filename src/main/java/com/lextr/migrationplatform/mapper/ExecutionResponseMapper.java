package com.lextr.migrationplatform.mapper;

import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.dto.ExecutionTargetResponse;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ExecutionResponseMapper {

    public ExecutionResponse toResponse(String executionId, String scope, String status, List<ExecutionTargetResponse> results) {
        return new ExecutionResponse(executionId, scope, status, results);
    }
}
