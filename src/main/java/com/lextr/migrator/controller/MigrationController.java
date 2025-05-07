package com.lextr.migrator.controller;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.FlywayException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/migration")
public class MigrationController {

    private final Flyway flyway;

    public MigrationController(@Value("${spring.flyway.locations}") String locations,
                               @Value("${spring.datasource.url}") String url,
                               @Value("${spring.datasource.username}") String username,
                               @Value("${spring.datasource.password}") String password,
                               @Value("${spring.flyway.cleanDisabled}") String isCleanDisabled,
                               @Value("${spring.flyway.schemas}") String schemas) {
        // Split locations by commas and initialize Flyway
        this.flyway = Flyway.configure()
                .dataSource(url, username, password)
                .locations(locations.split(","))
                .baselineOnMigrate(true)
                .schemas(schemas.split(","))
                .cleanDisabled(Boolean.parseBoolean(isCleanDisabled))
                .load();
    }

    @PostMapping
    public String migrate(@RequestParam Boolean cleanDB, @RequestParam(defaultValue = "false") Boolean force) {
        try {
            // Clean the database before migration if required
            if (cleanDB) {
                // Ensure clean is allowed before calling flyway.clean()
                if (flyway.getConfiguration().isCleanDisabled()) {
                    return "Database cleaning is disabled.";
                }
                flyway.clean();  // This will drop all objects in the schema
            }

            // Force migration if requested
            if (force) {
                // Repair the schema history table (use with caution)
                flyway.repair();
            }

            // Apply migrations
            flyway.migrate();
            return "Database cleaned and migration executed successfully.";
        } catch (FlywayException e) {
            return "Error during migration: " + e.getMessage();
        }
    }

    @PostMapping("/clean")
    public String clean() {
        try {
            // Ensure clean is allowed before calling flyway.clean()
            if (flyway.getConfiguration().isCleanDisabled()) {
                return "Database cleaning is disabled.";
            }
            flyway.clean();  // Clean only without migration
            return "Database cleaned successfully.";
        } catch (FlywayException e) {
            return "Error during cleaning: " + e.getMessage();
        }
    }

    @GetMapping("/info")
    public List<String> info() {
        // Return migration information
        return Arrays.stream(flyway.info().all())
                .map(m -> String.format("Version: %s, Description: %s, State: %s",
                        m.getVersion(), m.getDescription(), m.getState()))
                .toList();
    }
}
