package com.lextr.migrator.controller;

import com.lextr.migrator.platform.orchestration.LegacyMigrationService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/migration")
public class MigrationController {

    private final LegacyMigrationService legacyMigrationService;

    public MigrationController(LegacyMigrationService legacyMigrationService) {
        this.legacyMigrationService = legacyMigrationService;
    }

    @PostMapping
    public String migrate(@RequestParam Boolean cleanDB, @RequestParam(defaultValue = "false") Boolean force) {
        return legacyMigrationService.migrate(cleanDB, force);
    }

    @PostMapping("/clean")
    public String clean() {
        return legacyMigrationService.clean();
    }

    @GetMapping("/info")
    public List<String> info() {
        return legacyMigrationService.info();
    }
}
