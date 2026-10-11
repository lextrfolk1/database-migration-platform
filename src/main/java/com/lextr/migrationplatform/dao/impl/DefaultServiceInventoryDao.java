package com.lextr.migrationplatform.dao.impl;

import com.lextr.migrationplatform.config.MigrationPlatformInventoryConfiguration;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.dao.ServiceInventoryDao;
import com.lextr.migrationplatform.exception.MigrationPlatformException;
import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.model.InventorySnapshot;
import com.lextr.migrationplatform.model.ServiceMigrationDefinition;
import com.lextr.migrationplatform.model.ServiceTargetMapping;
import com.lextr.migrationplatform.model.TargetDatabase;
import com.lextr.migrationplatform.repository.PlatformConfigurationRepository;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

@Component
public class DefaultServiceInventoryDao implements ServiceInventoryDao {

    private final PlatformConfigurationRepository configurationRepository;
    private final Environment environment;
    private final MigrationPlatformProperties properties;

    public DefaultServiceInventoryDao(PlatformConfigurationRepository configurationRepository, Environment environment,
                                      MigrationPlatformProperties properties) {
        this.configurationRepository = configurationRepository;
        this.environment = environment;
        this.properties = properties;
    }

    @Override
    public InventorySnapshot loadInventory() {
        MigrationPlatformInventoryConfiguration configuration = configurationRepository.load();
        if (configuration.targets() == null || configuration.targets().isEmpty()
                || configuration.services() == null || configuration.services().isEmpty()) {
            throw new MigrationPlatformException("Migration platform configuration must define both targets and services");
        }

        Map<String, TargetDatabase> targets = new LinkedHashMap<>();
        configuration.targets().forEach((targetName, definition) -> targets.put(targetName, toTargetDatabase(targetName, definition)));

        Map<String, ServiceMigrationDefinition> services = new LinkedHashMap<>();
        configuration.services().forEach((serviceName, definition) -> services.put(serviceName, toServiceDefinition(serviceName, definition)));

        return new InventorySnapshot(configuration.defaultEnvironment(), Map.copyOf(targets), Map.copyOf(services));
    }

    private TargetDatabase toTargetDatabase(String targetName, MigrationPlatformInventoryConfiguration.TargetDatabaseConfig definition) {
        if (definition == null) {
            throw new ServiceNotFoundException("Target database definition missing for " + targetName);
        }
        String databaseType = normalize(definition.type());
        return new TargetDatabase(
                targetName,
                databaseType,
                definition.environment(),
                definition.url(),
                definition.username(),
                () -> definition.password() != null ? definition.password() : resolvePassword(definition.passwordEnv()),
                defaultDriver(databaseType, definition.driverClassName()),
                normalizeSchemas(definition.schema(), definition.schemas()),
                Boolean.TRUE.equals(definition.baselineOnMigrate()),
                definition.baselineVersion(),
                Boolean.TRUE.equals(definition.cleanDisabled()),
                definition.historyTablePrefix(),
                definition.placeholders() == null ? Map.of() : Map.copyOf(definition.placeholders())
        );
    }

    private ServiceMigrationDefinition toServiceDefinition(String serviceName, MigrationPlatformInventoryConfiguration.ServiceMigrationConfig definition) {
        if (definition == null || definition.targetMappings() == null || definition.targetMappings().isEmpty()) {
            throw new ServiceNotFoundException("Service migration definition missing target mappings for " + serviceName);
        }
        List<ServiceTargetMapping> targetMappings = definition.targetMappings().stream()
                .map(mapping -> new ServiceTargetMapping(
                        mapping.target(),
                        mapping.locations() == null ? List.of() : mapping.locations().stream().map(this::resolveLocation).toList(),
                        normalizeSchemas(mapping.schema(), mapping.schemas()),
                        mapping.historyTable(),
                        mapping.placeholders() == null ? Map.of() : Map.copyOf(mapping.placeholders()),
                        mapping.baselineOnMigrate()
                ))
                .toList();
        return new ServiceMigrationDefinition(serviceName, targetMappings);
    }

    // Locations without a classpath:/filesystem: prefix are relative to the configured migrations root.
    private String resolveLocation(String location) {
        if (location.startsWith("classpath:") || location.startsWith("filesystem:")) {
            return location;
        }
        Path root = Path.of(properties.getMigrationsRoot());
        if (!Files.isDirectory(root)) {
            throw new MigrationPlatformException("Migrations root does not exist: " + root.toAbsolutePath()
                    + " (set migration.platform.migrations-root)");
        }
        // Forward slashes work on every OS and avoid Windows backslashes in Flyway/Spring locations.
        return "filesystem:" + root.resolve(location).toString().replace('\\', '/');
    }

    private List<String> normalizeSchemas(String schema, List<String> schemas) {
        if (schemas != null && !schemas.isEmpty()) {
            return List.copyOf(schemas);
        }
        if (schema != null && !schema.isBlank()) {
            return List.of(schema);
        }
        return List.of();
    }

    private String resolvePassword(String passwordEnv) {
        if (passwordEnv == null || passwordEnv.isBlank()) {
            return null;
        }
        String password = environment.getProperty(passwordEnv);
        if (password == null) {
            throw new MigrationPlatformException("Required secret environment variable is not set: " + passwordEnv);
        }
        return password;
    }

    private String defaultDriver(String databaseType, String configuredDriver) {
        if (configuredDriver != null && !configuredDriver.isBlank()) {
            return configuredDriver;
        }
        return switch (normalize(databaseType)) {
            case "clickhouse" -> "com.clickhouse.jdbc.ClickHouseDriver";
            case "postgres" -> "org.postgresql.Driver";
            default -> configuredDriver;
        };
    }

    private String normalize(String databaseType) {
        return switch (Objects.requireNonNullElse(databaseType, "").toLowerCase(Locale.ROOT)) {
            case "postgresql" -> "postgres";
            default -> Objects.requireNonNullElse(databaseType, "").toLowerCase(Locale.ROOT);
        };
    }
}
