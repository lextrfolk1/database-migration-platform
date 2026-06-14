package com.lextr.migrator.platform.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

@Component
public class PlatformConfigLoader {

    private final PlatformProperties properties;
    private final ResourceLoader resourceLoader;
    private final ObjectMapper objectMapper;

    public PlatformConfigLoader(PlatformProperties properties, ResourceLoader resourceLoader) {
        this.properties = properties;
        this.resourceLoader = resourceLoader;
        this.objectMapper = new ObjectMapper(new YAMLFactory());
    }

    public PlatformConfiguration load() {
        Resource resource = resourceLoader.getResource(properties.getConfigLocation());
        if (!resource.exists()) {
            return new PlatformConfiguration(null, Map.of());
        }
        try (InputStream inputStream = resource.getInputStream()) {
            PlatformConfiguration configuration = objectMapper.readValue(inputStream, PlatformConfiguration.class);
            if (configuration == null) {
                return new PlatformConfiguration(null, Map.of());
            }
            return configuration;
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to load migration platform config from " + properties.getConfigLocation(), exception);
        }
    }
}
