package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;

import java.util.List;

public interface MigrationValidationService {

    List<ValidationIssue> validateTarget(MigrationTarget target, boolean allowRisky);

    boolean hasErrors(List<ValidationIssue> issues);
}
