package com.lextr.migrator.platform.inventory;

import com.lextr.migrator.platform.config.PlatformConfigLoader;
import com.lextr.migrator.platform.config.PlatformConfiguration;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class InventoryService {

    private static final String DEFAULT_DATABASE = "postgres";

    private final PlatformConfigLoader configLoader;
    private final Environment environment;

    public InventoryService(PlatformConfigLoader configLoader, Environment environment) {
        this.configLoader = configLoader;
        this.environment = environment;
    }

    public List<MigrationTarget> listTargets() {
        List<MigrationTarget> configuredTargets = configuredTargets();
        if (!configuredTargets.isEmpty()) {
            return configuredTargets;
        }
        return legacyTargets();
    }

    public List<String> listServices() {
        return listTargets().stream()
                .map(MigrationTarget::service)
                .distinct()
                .sorted()
                .toList();
    }

    public List<String> listDatabasesForService(String service) {
        return listTargets().stream()
                .filter(target -> target.service().equals(service))
                .map(MigrationTarget::database)
                .distinct()
                .sorted()
                .toList();
    }

    public MigrationTarget getRequiredTarget(String environmentName, String service, String database) {
        return listTargets().stream()
                .filter(target -> target.environment().equals(environmentName))
                .filter(target -> target.service().equals(service))
                .filter(target -> target.database().equals(normalize(database)))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Unknown migration target for environment=" + environmentName + ", service=" + service + ", database=" + database));
    }

    private List<MigrationTarget> configuredTargets() {
        PlatformConfiguration configuration = configLoader.load();
        if (configuration.environments() == null || configuration.environments().isEmpty()) {
            return List.of();
        }

        List<MigrationTarget> targets = new ArrayList<>();
        configuration.environments().forEach((environmentName, environmentDefinition) -> {
            Map<String, Map<String, PlatformConfiguration.DatabaseDefinition>> services =
                    environmentDefinition.services() == null ? Map.of() : environmentDefinition.services();
            services.forEach((serviceName, databases) -> {
                Map<String, PlatformConfiguration.DatabaseDefinition> safeDatabases = databases == null ? Map.of() : databases;
                safeDatabases.forEach((databaseName, databaseDefinition) -> targets.add(toTarget(environmentName, serviceName, databaseName, databaseDefinition)));
            });
        });

        return targets.stream()
                .sorted(Comparator.comparing(MigrationTarget::environment)
                        .thenComparing(MigrationTarget::service)
                        .thenComparing(MigrationTarget::database))
                .toList();
    }

    private MigrationTarget toTarget(String environmentName, String serviceName, String databaseName,
                                     PlatformConfiguration.DatabaseDefinition definition) {
        if (definition == null) {
            throw new IllegalArgumentException("Database definition missing for service " + serviceName + " and database " + databaseName);
        }
        String password = definition.password() != null ? definition.password() : resolvePassword(definition.passwordEnv());
        return new MigrationTarget(
                environmentName,
                serviceName,
                normalize(databaseName),
                definition.url(),
                definition.username(),
                password,
                defaultDriver(normalize(databaseName), definition.driverClassName()),
                definition.locations() == null ? List.of() : List.copyOf(definition.locations()),
                definition.schemas() == null ? List.of() : List.copyOf(definition.schemas()),
                Boolean.TRUE.equals(definition.baselineOnMigrate()),
                Boolean.TRUE.equals(definition.cleanDisabled()),
                definition.historyTable(),
                definition.placeholders() == null ? Map.of() : Map.copyOf(definition.placeholders()),
                false
        );
    }

    private List<MigrationTarget> legacyTargets() {
        String locationsProperty = environment.getProperty("spring.flyway.locations", "");
        String datasourceUrl = environment.getProperty("spring.datasource.url");
        if (datasourceUrl == null || locationsProperty.isBlank()) {
            return List.of();
        }

        List<String> rawLocations = Arrays.stream(locationsProperty.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .toList();
        List<String> sharedLocations = rawLocations.stream()
                .filter(location -> location.contains("/00_"))
                .toList();
        Map<String, List<String>> serviceLocations = new LinkedHashMap<>();
        for (String location : rawLocations) {
            if (sharedLocations.contains(location)) {
                continue;
            }
            String serviceName = deriveServiceName(location);
            List<String> combined = new ArrayList<>(sharedLocations);
            combined.add(location);
            serviceLocations.put(serviceName, combined);
        }

        List<String> schemas = Arrays.stream(environment.getProperty("spring.flyway.schemas", "").split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .toList();

        return serviceLocations.entrySet().stream()
                .map(entry -> new MigrationTarget(
                        "legacy",
                        entry.getKey(),
                        DEFAULT_DATABASE,
                        datasourceUrl,
                        environment.getProperty("spring.datasource.username"),
                        environment.getProperty("spring.datasource.password"),
                        environment.getProperty("spring.datasource.driver-class-name", "org.postgresql.Driver"),
                        entry.getValue(),
                        schemas,
                        environment.getProperty("spring.flyway.baseline-on-migrate", Boolean.class, true),
                        environment.getProperty("spring.flyway.cleanDisabled", Boolean.class, false),
                        null,
                        Map.of(),
                        true
                ))
                .sorted(Comparator.comparing(MigrationTarget::service))
                .toList();
    }

    private String deriveServiceName(String location) {
        String token = location.substring(location.lastIndexOf('/') + 1);
        int separatorIndex = token.indexOf('_');
        if (separatorIndex >= 0 && separatorIndex < token.length() - 1 && isDigits(token.substring(0, separatorIndex))) {
            token = token.substring(separatorIndex + 1);
        }
        return token.replace('_', '-');
    }

    private boolean isDigits(String value) {
        return value.chars().allMatch(Character::isDigit);
    }

    private String resolvePassword(String passwordEnv) {
        if (passwordEnv == null || passwordEnv.isBlank()) {
            return null;
        }
        String password = environment.getProperty(passwordEnv);
        if (password == null) {
            throw new IllegalStateException("Required secret environment variable is not set: " + passwordEnv);
        }
        return password;
    }

    private String defaultDriver(String databaseName, String configuredDriver) {
        if (configuredDriver != null && !configuredDriver.isBlank()) {
            return configuredDriver;
        }
        return switch (normalize(databaseName)) {
            case "clickhouse" -> "com.clickhouse.jdbc.ClickHouseDriver";
            case "postgres", "postgresql" -> "org.postgresql.Driver";
            default -> configuredDriver;
        };
    }

    private String normalize(String databaseName) {
        return Objects.requireNonNullElse(databaseName, "").toLowerCase(Locale.ROOT);
    }
}
