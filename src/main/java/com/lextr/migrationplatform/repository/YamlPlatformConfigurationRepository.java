package com.lextr.migrationplatform.repository;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.lextr.migrationplatform.config.MigrationPlatformInventoryConfiguration;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.exception.MigrationPlatformException;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Repository;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

@Repository
public class YamlPlatformConfigurationRepository implements PlatformConfigurationRepository {

    private final MigrationPlatformProperties properties;
    private final ResourceLoader resourceLoader;
    private final ObjectMapper objectMapper = new ObjectMapper(new YAMLFactory());

    public YamlPlatformConfigurationRepository(MigrationPlatformProperties properties, ResourceLoader resourceLoader) {
        this.properties = properties;
        this.resourceLoader = resourceLoader;
    }

    @Override
    public MigrationPlatformInventoryConfiguration load() {
        Resource resource = resourceLoader.getResource(properties.getConfigLocation());
        if (!resource.exists()) {
            return new MigrationPlatformInventoryConfiguration(null, Map.of(), Map.of(), Map.of());
        }
        try (InputStream inputStream = resource.getInputStream()) {
            MigrationPlatformInventoryConfiguration configuration =
                    objectMapper.readValue(inputStream, MigrationPlatformInventoryConfiguration.class);
            if (configuration == null) {
                return new MigrationPlatformInventoryConfiguration(null, Map.of(), Map.of(), Map.of());
            }
            return configuration;
        } catch (IOException exception) {
            throw new MigrationPlatformException("Unable to load migration platform config from " + properties.getConfigLocation(), exception);
        }
    }
}
