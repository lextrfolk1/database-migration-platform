package com.lextr.migrationplatform.controller;

import com.lextr.migrationplatform.dto.InventoryItemResponse;
import com.lextr.migrationplatform.dto.ServiceDetailsResponse;
import com.lextr.migrationplatform.dto.TargetDatabaseResponse;
import com.lextr.migrationplatform.mapper.InventoryResponseMapper;
import com.lextr.migrationplatform.orchestration.MigrationPlatformOrchestrator;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class InventoryController {

    private final MigrationPlatformOrchestrator orchestrator;
    private final InventoryResponseMapper inventoryResponseMapper;

    public InventoryController(MigrationPlatformOrchestrator orchestrator, InventoryResponseMapper inventoryResponseMapper) {
        this.orchestrator = orchestrator;
        this.inventoryResponseMapper = inventoryResponseMapper;
    }

    @GetMapping("/inventory")
    public List<InventoryItemResponse> inventory() {
        return orchestrator.inventory().stream()
                .map(inventoryResponseMapper::toResponse)
                .toList();
    }

    @GetMapping("/targets")
    public List<TargetDatabaseResponse> targets() {
        return orchestrator.targets().stream()
                .map(target -> new TargetDatabaseResponse(
                        target.name(),
                        target.databaseType(),
                        target.environment(),
                        target.defaultSchemas(),
                        target.cleanDisabled()
                ))
                .toList();
    }

    @GetMapping("/targets/{target}")
    public TargetDatabaseResponse target(@PathVariable String target) {
        var resolved = orchestrator.target(target);
        return new TargetDatabaseResponse(
                resolved.name(),
                resolved.databaseType(),
                resolved.environment(),
                resolved.defaultSchemas(),
                resolved.cleanDisabled()
        );
    }

    @GetMapping("/services")
    public List<String> services() {
        return orchestrator.services();
    }

    @GetMapping("/services/{service}")
    public ServiceDetailsResponse service(@PathVariable String service) {
        return new ServiceDetailsResponse(service, orchestrator.serviceTargets(service));
    }

    @GetMapping("/services/{service}/databases")
    public List<String> databases(@PathVariable String service) {
        return orchestrator.serviceTargets(service);
    }
}
