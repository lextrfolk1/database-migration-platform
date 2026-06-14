package com.lextr.migrator.platform.planning;

import java.util.List;

public record MigrationPlan(
        List<TargetMigrationPlan> targets
) {
}
