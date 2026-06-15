package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import org.springframework.core.io.Resource;

import java.util.List;
import java.util.Set;

public interface ValidationStrategy {

    List<ValidationIssue> validate(MigrationTarget target, List<Resource> resources, Set<String> versions, boolean allowRisky);
}
