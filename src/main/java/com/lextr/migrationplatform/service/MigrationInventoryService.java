package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.model.InventorySnapshot;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ServiceMigrationDefinition;
import com.lextr.migrationplatform.model.TargetDatabase;

import java.util.List;

public interface MigrationInventoryService {

    InventorySnapshot inventorySnapshot();

    List<MigrationTarget> resolvedTargets();

    List<TargetDatabase> targetDatabases();

    TargetDatabase getRequiredTargetDatabase(String targetName);

    List<String> listServices();

    ServiceMigrationDefinition getRequiredServiceDefinition(String serviceName);

    List<String> listTargetNamesForService(String serviceName);

    List<MigrationTarget> resolveRequest(MigrationRequest request);
}
