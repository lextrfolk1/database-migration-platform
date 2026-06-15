package com.lextr.migrationplatform.cli;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.dto.MigrationActionRequest;
import com.lextr.migrationplatform.mapper.MigrationRequestMapper;
import com.lextr.migrationplatform.model.RunMode;
import com.lextr.migrationplatform.orchestration.MigrationPlatformOrchestrator;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ExitCodeGenerator;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
public class CliCommandRunner implements ApplicationRunner, ExitCodeGenerator {

    private static final Set<String> ROOT_COMMANDS = Set.of("inventory", "validate", "plan", "run", "history", "rebuild", "repair", "targets", "services");

    private final MigrationPlatformOrchestrator orchestrator;
    private final MigrationPlatformProperties properties;
    private final MigrationRequestMapper requestMapper;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
    private int exitCode;

    public CliCommandRunner(MigrationPlatformOrchestrator orchestrator,
                            MigrationPlatformProperties properties,
                            MigrationRequestMapper requestMapper) {
        this.orchestrator = orchestrator;
        this.properties = properties;
        this.requestMapper = requestMapper;
    }

    public static boolean isCliCommand(String[] args) {
        return args != null && args.length > 0 && ROOT_COMMANDS.contains(args[0]);
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        String[] sourceArgs = args.getSourceArgs();
        if (!isCliCommand(sourceArgs)) {
            return;
        }

        String command = sourceArgs[0];
        Map<String, String> options = parseOptions(sourceArgs);

        try {
            Object response = switch (command) {
                case "inventory" -> orchestrator.inventory();
                case "validate" -> orchestrator.validate(requestMapper.toModel(toRequest(options), RunMode.DELTA));
                case "plan" -> orchestrator.plan(requestMapper.toModel(toRequest(options), RunMode.DELTA));
                case "run" -> orchestrator.run(requestMapper.toModel(toRequest(options), RunMode.DELTA));
                case "rebuild" -> orchestrator.run(requestMapper.toModel(toRequest(options), RunMode.REBUILD));
                case "repair" -> orchestrator.repair(requestMapper.toModel(toRequest(options), RunMode.DELTA));
                case "history" -> orchestrator.history();
                case "targets" -> runTargetCommand(sourceArgs);
                case "services" -> runServiceCommand(sourceArgs);
                default -> throw new IllegalArgumentException("Unsupported CLI command: " + command);
            };
            System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(response));
        } catch (Exception exception) {
            exitCode = 1;
            System.err.println(exception.getMessage());
        }
    }

    private Object runTargetCommand(String[] sourceArgs) {
        if (sourceArgs.length < 2 || "list".equals(sourceArgs[1])) {
            return orchestrator.targets();
        }
        if ("show".equals(sourceArgs[1]) && sourceArgs.length >= 3) {
            return orchestrator.target(sourceArgs[2]);
        }
        throw new IllegalArgumentException("Usage: migration targets list | migration targets show <target>");
    }

    private Object runServiceCommand(String[] sourceArgs) {
        if (sourceArgs.length < 2 || "list".equals(sourceArgs[1])) {
            return orchestrator.services();
        }
        if ("show".equals(sourceArgs[1]) && sourceArgs.length >= 3) {
            return new com.lextr.migrationplatform.dto.ServiceDetailsResponse(sourceArgs[2], orchestrator.serviceTargets(sourceArgs[2]));
        }
        throw new IllegalArgumentException("Usage: migration services list | migration services show <service>");
    }

    private MigrationActionRequest toRequest(Map<String, String> options) {
        return new MigrationActionRequest(
                options.containsKey("all-services") ? "all-services" : "service",
                options.get("service"),
                options.get("target"),
                options.get("db"),
                options.getOrDefault("env", "dev"),
                options.getOrDefault("mode", "delta"),
                options.containsKey("all-targets") || options.containsKey("all-databases"),
                options.containsKey("continue-on-error"),
                options.containsKey("allow-risky"),
                options.containsKey("confirm"),
                options.getOrDefault("requested-by", properties.getDefaultRequestedBy())
        );
    }

    private Map<String, String> parseOptions(String[] sourceArgs) {
        Map<String, String> options = new HashMap<>();
        for (int index = 1; index < sourceArgs.length; index++) {
            String token = sourceArgs[index];
            if (!token.startsWith("--")) {
                continue;
            }
            String name = token.substring(2);
            if (index + 1 < sourceArgs.length && !sourceArgs[index + 1].startsWith("--")) {
                options.put(name, sourceArgs[++index]);
            } else {
                options.put(name, "true");
            }
        }
        return options;
    }

    @Override
    public int getExitCode() {
        return exitCode;
    }
}
