package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.factory.FlywayAdapterFactory;
import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.TargetMigrationPlan;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.service.MigrationPlanService;
import com.lextr.migrationplatform.service.MigrationValidationService;
import org.flywaydb.core.api.MigrationInfo;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class MigrationPlanServiceImpl implements MigrationPlanService {

    private final FlywayAdapterFactory flywayAdapterFactory;
    private final MigrationValidationService validationService;

    public MigrationPlanServiceImpl(FlywayAdapterFactory flywayAdapterFactory, MigrationValidationService validationService) {
        this.flywayAdapterFactory = flywayAdapterFactory;
        this.validationService = validationService;
    }

    @Override
    public MigrationPlan createPlan(List<MigrationTarget> targets, boolean allowRisky) {
        List<TargetMigrationPlan> plans = new ArrayList<>();
        int order = 1;
        for (MigrationTarget target : targets) {
            FlywayOperations flyway = flywayAdapterFactory.getRequired(target.databaseType()).create(target);
            List<ValidationIssue> validationIssues = validationService.validateTarget(target, allowRisky);
            List<String> checksumIssues = new ArrayList<>();
            try {
                flyway.validate();
            } catch (Exception exception) {
                checksumIssues.add(exception.getMessage());
            }

            List<String> alreadyApplied = new ArrayList<>();
            List<String> pendingVersioned = new ArrayList<>();
            List<String> repeatableToRerun = new ArrayList<>();
            List<String> riskWarnings = validationIssues.stream()
                    .filter(issue -> issue.code().contains("RISK"))
                    .map(ValidationIssue::message)
                    .toList();

            for (MigrationInfo info : flyway.infoAll()) {
                String label = format(info);
                if (info.getInstalledOn() != null) {
                    alreadyApplied.add(label);
                }
                if ("PENDING".equals(info.getState().name()) && info.getVersion() != null) {
                    pendingVersioned.add(label);
                }
                if (info.getVersion() == null && ("PENDING".equals(info.getState().name()) || "OUTDATED".equals(info.getState().name()))) {
                    repeatableToRerun.add(label);
                }
            }

            plans.add(new TargetMigrationPlan(
                    target.service(),
                    target.targetName(),
                    target.databaseType(),
                    target.environment(),
                    target.locations(),
                    target.historyTable(),
                    alreadyApplied,
                    pendingVersioned,
                    repeatableToRerun,
                    checksumIssues,
                    validationIssues.stream().filter(issue -> issue.severity() != com.lextr.migrationplatform.model.IssueSeverity.ERROR).toList(),
                    riskWarnings,
                    order++
            ));
        }
        return new MigrationPlan(plans);
    }

    private String format(MigrationInfo info) {
        String version = info.getVersion() == null ? "R" : info.getVersion().getVersion();
        return version + " :: " + info.getDescription() + " [" + info.getState() + "]";
    }
}
