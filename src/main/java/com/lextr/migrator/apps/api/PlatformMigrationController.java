package com.lextr.migrator.apps.api;

import com.lextr.migrator.platform.orchestration.ExecutionResponse;
import com.lextr.migrator.platform.orchestration.ExecutionScope;
import com.lextr.migrator.platform.orchestration.MigrationOrchestrator;
import com.lextr.migrator.platform.orchestration.MigrationRequest;
import com.lextr.migrator.platform.orchestration.RunMode;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/migrations")
public class PlatformMigrationController {

    private final MigrationOrchestrator orchestrator;

    public PlatformMigrationController(MigrationOrchestrator orchestrator) {
        this.orchestrator = orchestrator;
    }

    @PostMapping("/validate")
    public Object validate(@RequestBody MigrationActionRequest request) {
        return orchestrator.validate(toRequest(request, RunMode.DELTA));
    }

    @PostMapping("/plan")
    public Object plan(@RequestBody MigrationActionRequest request) {
        return orchestrator.plan(toRequest(request, RunMode.DELTA));
    }

    @PostMapping("/run")
    public ExecutionResponse run(@RequestBody MigrationActionRequest request) {
        return orchestrator.run(toRequest(request, RunMode.DELTA));
    }

    @PostMapping("/rebuild")
    public ExecutionResponse rebuild(@RequestBody MigrationActionRequest request) {
        return orchestrator.run(toRequest(request, RunMode.REBUILD));
    }

    @PostMapping("/repair")
    public ExecutionResponse repair(@RequestBody MigrationActionRequest request) {
        return orchestrator.repair(toRequest(request, RunMode.DELTA));
    }

    @GetMapping("/history")
    public Object history() {
        return orchestrator.history();
    }

    @GetMapping("/status/{executionId}")
    public Object status(@PathVariable String executionId) {
        return orchestrator.status(executionId);
    }

    private MigrationRequest toRequest(MigrationActionRequest request, RunMode fallbackMode) {
        ExecutionScope scope = request.scope() != null && request.scope().equalsIgnoreCase("all-services")
                ? ExecutionScope.ALL_SERVICES
                : ExecutionScope.SERVICE;
        RunMode mode = request.mode() == null ? fallbackMode : RunMode.valueOf(request.mode().toUpperCase());
        return new MigrationRequest(
                scope,
                request.service(),
                request.database(),
                request.environment(),
                Boolean.TRUE.equals(request.allDatabases()),
                mode,
                Boolean.TRUE.equals(request.continueOnError()),
                Boolean.TRUE.equals(request.allowRisky()),
                Boolean.TRUE.equals(request.confirm()),
                request.requestedBy()
        );
    }
}
