package com.lextr.migrationplatform;

import com.lextr.migrationplatform.cli.CliCommandRunner;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.jdbc.JdbcRepositoriesAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.ConfigurableApplicationContext;

@EnableConfigurationProperties(MigrationPlatformProperties.class)
@SpringBootApplication(exclude = {
        DataSourceAutoConfiguration.class,
        JdbcRepositoriesAutoConfiguration.class
})
public class MigrationPlatformApplication {

    public static void main(String[] args) {
        SpringApplicationBuilder builder = new SpringApplicationBuilder(MigrationPlatformApplication.class);
        if (CliCommandRunner.isCliCommand(args)) {
            builder.web(WebApplicationType.NONE);
        }
        ConfigurableApplicationContext context = builder.run(args);
        if (CliCommandRunner.isCliCommand(args)) {
            int exitCode = org.springframework.boot.SpringApplication.exit(context);
            System.exit(exitCode);
        }
    }
}
