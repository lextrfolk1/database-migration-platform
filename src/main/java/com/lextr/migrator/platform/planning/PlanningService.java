package com.lextr.migrator.platform.planning;

import com.lextr.migrator.integrations.flyway.FlywayFactory;
import com.lextr.migrator.integrations.flyway.FlywayOperations;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.validation.IssueSeverity;
import com.lextr.migrator.platform.validation.MigrationValidationService;
import com.lextr.migrator.platform.validation.ValidationIssue;
import org.flywaydb.core.api.MigrationInfo;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PlanningService {

    private final FlywayFactory flywayFactory;
    private final MigrationValidationService validationService;

    public PlanningService(FlywayFactory flywayFactory, MigrationValidationService validationService) {
        this.flywayFactory = flywayFactory;
        this.validationService = validationService;
    }

    public MigrationPlan createPlan(List<MigrationTarget> targets, boolean allowRisky) {
        List<TargetMigrationPlan> plans = new ArrayList<>();
        int order = 1;
        for (MigrationTarget target : targets) {
            FlywayOperations flyway = flywayFactory.create(target);
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
            List<String> riskWarnings = new ArrayList<>();

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

            validationIssues.stream()
                    .filter(issue -> issue.severity() == IssueSeverity.WARNING && issue.code().contains("RISK"))
                    .map(ValidationIssue::message)
                    .forEach(riskWarnings::add);

            plans.add(new TargetMigrationPlan(
                    target.service(),
                    target.database(),
                    target.environment(),
                    target.locations(),
                    alreadyApplied,
                    pendingVersioned,
                    repeatableToRerun,
                    checksumIssues,
                    validationIssues.stream().filter(issue -> issue.severity() == IssueSeverity.WARNING).toList(),
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
