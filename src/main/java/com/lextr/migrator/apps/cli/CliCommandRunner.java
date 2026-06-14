package com.lextr.migrator.apps.cli;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lextr.migrator.platform.config.PlatformProperties;
import com.lextr.migrator.platform.orchestration.ExecutionScope;
import com.lextr.migrator.platform.orchestration.MigrationOrchestrator;
import com.lextr.migrator.platform.orchestration.MigrationRequest;
import com.lextr.migrator.platform.orchestration.RunMode;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ExitCodeGenerator;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
public class CliCommandRunner implements ApplicationRunner, ExitCodeGenerator {

    private static final Set<String> COMMANDS = Set.of("inventory", "validate", "plan", "run", "history", "rebuild", "repair");

    private final MigrationOrchestrator orchestrator;
    private final PlatformProperties properties;
    private final ObjectMapper objectMapper;
    private int exitCode = 0;

    public CliCommandRunner(MigrationOrchestrator orchestrator, PlatformProperties properties) {
        this.orchestrator = orchestrator;
        this.properties = properties;
        this.objectMapper = new ObjectMapper().findAndRegisterModules();
    }

    public static boolean isCliCommand(String[] args) {
        return args != null && args.length > 0 && COMMANDS.contains(args[0]);
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
                case "validate" -> orchestrator.validate(toRequest(command, options));
                case "plan" -> orchestrator.plan(toRequest(command, options));
                case "run" -> orchestrator.run(toRequest(command, options));
                case "rebuild" -> orchestrator.run(toRequest(command, options));
                case "repair" -> orchestrator.repair(toRequest(command, options));
                case "history" -> orchestrator.history();
                default -> throw new IllegalArgumentException("Unsupported CLI command: " + command);
            };
            System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(response));
        } catch (Exception exception) {
            exitCode = 1;
            System.err.println(exception.getMessage());
        }
    }

    private MigrationRequest toRequest(String command, Map<String, String> options) {
        boolean allServices = options.containsKey("all-services");
        boolean allDatabases = options.containsKey("all-databases");
        ExecutionScope scope = allServices ? ExecutionScope.ALL_SERVICES : ExecutionScope.SERVICE;
        RunMode mode = "rebuild".equals(command)
                ? RunMode.REBUILD
                : RunMode.valueOf(options.getOrDefault("mode", "delta").toUpperCase());
        return new MigrationRequest(
                scope,
                options.get("service"),
                options.get("db"),
                options.getOrDefault("env", "dev"),
                allDatabases,
                mode,
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
