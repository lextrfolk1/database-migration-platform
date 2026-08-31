package com.lextr.migrationplatform;

import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.repository.YamlPlatformConfigurationRepository;
import com.lextr.migrationplatform.util.MigrationResourceLocator;
import com.lextr.migrationplatform.validation.MigrationFilenameParser;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.Resource;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DatabaseScriptsServiceMigrationTest {

    private final YamlPlatformConfigurationRepository repository = new YamlPlatformConfigurationRepository(
            new MigrationPlatformProperties(),
            new org.springframework.core.io.DefaultResourceLoader()
    );
    private final MigrationResourceLocator resourceLocator = new MigrationResourceLocator();
    private final MigrationFilenameParser filenameParser = new MigrationFilenameParser();

    @Test
    void databaseScriptsServiceIsRegisteredInPlatformYml() {
        var config = repository.load();
        assertTrue(config.services().containsKey("database-scripts"), "database-scripts service must be configured");

        var serviceConfig = config.services().get("database-scripts");
        assertNotNull(serviceConfig);
        assertEquals(2, serviceConfig.targetMappings().size());

        var targets = serviceConfig.targetMappings().stream()
                .map(m -> m.target())
                .toList();
        assertTrue(targets.contains("postgres-main-dev"));
        assertTrue(targets.contains("clickhouse-analytics-dev"));
    }

    @Test
    void databaseScriptsPostgresMigrationFilesAreValidAndParsable() {
        List<Resource> resources = resourceLocator.sqlResources("classpath:migrations/database-scripts/postgres");
        assertEquals(7, resources.size(), "Expected 7 SQL migration scripts under database-scripts/postgres");

        for (Resource resource : resources) {
            String filename = resource.getFilename();
            assertNotNull(filename);
            var parsed = filenameParser.parse(filename);
            assertNotNull(parsed.version(), "Migration version must be present for " + filename);
        }
    }
}
