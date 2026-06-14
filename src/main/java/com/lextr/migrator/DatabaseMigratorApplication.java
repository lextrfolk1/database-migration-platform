package com.lextr.migrator;

import com.lextr.migrator.apps.cli.CliCommandRunner;
import com.lextr.migrator.platform.config.PlatformProperties;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
@EnableConfigurationProperties(PlatformProperties.class)
public class DatabaseMigratorApplication {
    public static void main(String[] args) {
        SpringApplicationBuilder builder = new SpringApplicationBuilder(DatabaseMigratorApplication.class);
        if (CliCommandRunner.isCliCommand(args)) {
            builder.web(WebApplicationType.NONE);
        }
        ConfigurableApplicationContext context = builder.run(args);
        if (CliCommandRunner.isCliCommand(args)) {
            int exitCode = SpringApplication.exit(context);
            System.exit(exitCode);
        }
    }
}
