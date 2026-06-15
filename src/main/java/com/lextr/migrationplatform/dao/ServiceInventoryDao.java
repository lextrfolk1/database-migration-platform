package com.lextr.migrationplatform.dao;

import com.lextr.migrationplatform.model.InventorySnapshot;

public interface ServiceInventoryDao {

    InventorySnapshot loadInventory();
}
