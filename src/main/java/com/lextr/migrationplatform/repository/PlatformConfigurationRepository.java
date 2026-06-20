package com.lextr.migrationplatform.repository;

import com.lextr.migrationplatform.config.MigrationPlatformInventoryConfiguration;

public interface PlatformConfigurationRepository {

    MigrationPlatformInventoryConfiguration load();
}
