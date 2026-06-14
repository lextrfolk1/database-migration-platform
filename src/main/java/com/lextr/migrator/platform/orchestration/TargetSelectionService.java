package com.lextr.migrator.platform.orchestration;

import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class TargetSelectionService {

    private final InventoryService inventoryService;

    public TargetSelectionService(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    public List<MigrationTarget> resolve(MigrationRequest request) {
        if (request.scope() == ExecutionScope.SERVICE) {
            if (request.service() == null || request.service().isBlank()) {
                throw new IllegalArgumentException("Service name is required for service scope");
            }
            if (request.database() == null || request.database().isBlank()) {
                throw new IllegalArgumentException("Database name is required for service scope");
            }
            return List.of(inventoryService.getRequiredTarget(request.environment(), request.service(), request.database()));
        }

        if (!request.allDatabases() && (request.database() == null || request.database().isBlank())) {
            throw new IllegalArgumentException("Database name is required unless --all-databases is set");
        }

        List<MigrationTarget> targets = inventoryService.listTargets().stream()
                .filter(target -> target.environment().equals(request.environment()))
                .filter(target -> request.allDatabases() || target.database().equals(request.database()))
                .sorted(Comparator.comparing(MigrationTarget::service).thenComparing(MigrationTarget::database))
                .toList();
        if (targets.isEmpty()) {
            throw new IllegalArgumentException("No migration targets found for the requested scope");
        }
        return targets;
    }
}
