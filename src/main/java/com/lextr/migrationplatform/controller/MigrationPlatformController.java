package com.lextr.migrationplatform.controller;

import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.dto.MigrationActionRequest;
import com.lextr.migrationplatform.mapper.MigrationRequestMapper;
import com.lextr.migrationplatform.model.RunMode;
import com.lextr.migrationplatform.orchestration.MigrationPlatformOrchestrator;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/migrations")
public class MigrationPlatformController {

    private final MigrationPlatformOrchestrator orchestrator;
    private final MigrationRequestMapper requestMapper;

    public MigrationPlatformController(MigrationPlatformOrchestrator orchestrator, MigrationRequestMapper requestMapper) {
        this.orchestrator = orchestrator;
        this.requestMapper = requestMapper;
    }

    @PostMapping("/validate")
    public Object validate(@RequestBody MigrationActionRequest request) {
        return orchestrator.validate(requestMapper.toModel(request, RunMode.DELTA));
    }

    @PostMapping("/plan")
    public Object plan(@RequestBody MigrationActionRequest request) {
        return orchestrator.plan(requestMapper.toModel(request, RunMode.DELTA));
    }

    @PostMapping("/run")
    public ExecutionResponse run(@RequestBody MigrationActionRequest request) {
        return orchestrator.run(requestMapper.toModel(request, RunMode.DELTA));
    }

    @PostMapping("/rebuild")
    public ExecutionResponse rebuild(@RequestBody MigrationActionRequest request) {
        return orchestrator.run(requestMapper.toModel(request, RunMode.REBUILD));
    }

    @PostMapping("/repair")
    public ExecutionResponse repair(@RequestBody MigrationActionRequest request) {
        return orchestrator.repair(requestMapper.toModel(request, RunMode.DELTA));
    }

    @GetMapping("/history")
    public Object history() {
        return orchestrator.history();
    }

    @GetMapping("/status/{executionId}")
    public Object status(@PathVariable String executionId) {
        return orchestrator.status(executionId);
    }
}
