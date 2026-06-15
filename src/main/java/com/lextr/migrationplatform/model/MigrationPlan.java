package com.lextr.migrationplatform.model;

import java.util.List;

public record MigrationPlan(
        List<TargetMigrationPlan> targets
) {
}
