package com.lextr.migrator.apps.api;

import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationResourceLocator;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class InventoryController {

    private final InventoryService inventoryService;
    private final MigrationResourceLocator resourceLocator;

    public InventoryController(InventoryService inventoryService, MigrationResourceLocator resourceLocator) {
        this.inventoryService = inventoryService;
        this.resourceLocator = resourceLocator;
    }

    @GetMapping("/inventory")
    public List<Map<String, Object>> inventory() {
        return inventoryService.listTargets().stream()
                .map(target -> Map.of(
                        "service", target.service(),
                        "database", target.database(),
                        "environment", target.environment(),
                        "locations", target.locations(),
                        "migrationCount", target.locations().stream().mapToInt(location -> resourceLocator.sqlResources(location).size()).sum(),
                        "legacyCompatible", target.legacyCompatible()
                ))
                .toList();
    }

    @GetMapping("/services")
    public List<String> services() {
        return inventoryService.listServices();
    }

    @GetMapping("/services/{service}/databases")
    public List<String> databases(@PathVariable String service, @RequestParam(required = false) String environment) {
        if (environment == null || environment.isBlank()) {
            return inventoryService.listDatabasesForService(service);
        }
        return inventoryService.listTargets().stream()
                .filter(target -> target.service().equals(service))
                .filter(target -> target.environment().equals(environment))
                .map(MigrationTarget::database)
                .distinct()
                .sorted()
                .toList();
    }
}
