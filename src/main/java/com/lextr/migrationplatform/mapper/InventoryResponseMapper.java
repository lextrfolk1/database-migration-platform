package com.lextr.migrationplatform.mapper;

import com.lextr.migrationplatform.dto.InventoryItemResponse;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.util.MigrationResourceLocator;
import org.springframework.stereotype.Component;

@Component
public class InventoryResponseMapper {

    private final MigrationResourceLocator resourceLocator;

    public InventoryResponseMapper(MigrationResourceLocator resourceLocator) {
        this.resourceLocator = resourceLocator;
    }

    public InventoryItemResponse toResponse(MigrationTarget target) {
        int migrationCount = target.locations().stream()
                .mapToInt(location -> resourceLocator.sqlResources(location).size())
                .sum();
        return new InventoryItemResponse(
                target.service(),
                target.targetName(),
                target.databaseType(),
                target.environment(),
                target.locations(),
                target.schemas(),
                target.historyTable(),
                migrationCount
        );
    }
}
