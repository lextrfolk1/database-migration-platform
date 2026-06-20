package com.lextr.migrationplatform;

import com.lextr.migrationplatform.factory.DatabaseAdapterFactory;
import com.lextr.migrationplatform.factory.ValidationStrategyFactory;
import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.service.impl.MigrationValidationServiceImpl;
import com.lextr.migrationplatform.strategy.CommonSqlValidationStrategy;
import com.lextr.migrationplatform.strategy.DefaultRiskDetectionStrategy;
import com.lextr.migrationplatform.strategy.PostgresMigrationStrategy;
import com.lextr.migrationplatform.strategy.PostgresSqlValidationStrategy;
import com.lextr.migrationplatform.strategy.StrictRiskDetectionStrategy;
import com.lextr.migrationplatform.util.MigrationResourceLocator;
import com.lextr.migrationplatform.validation.MigrationFilenameParser;
import com.lextr.migrationplatform.validation.SqlRiskScanner;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MigrationValidationServiceTest {

    @Test
    void blocksRiskySqlWithoutOverride() {
        MigrationResourceLocator locator = mock(MigrationResourceLocator.class);
        DatabaseAdapterFactory adapterFactory = mock(DatabaseAdapterFactory.class);
        when(adapterFactory.supports("postgres")).thenReturn(true);
        when(locator.sqlResources("classpath:test")).thenReturn(List.of(resource("V001__drop_table.sql", "TRUNCATE table_x;")));

        DefaultRiskDetectionStrategy defaultRisk = new DefaultRiskDetectionStrategy(new SqlRiskScanner());
        StrictRiskDetectionStrategy strictRisk = new StrictRiskDetectionStrategy(defaultRisk);
        ValidationStrategyFactory validationStrategyFactory = new ValidationStrategyFactory(List.of(
                new CommonSqlValidationStrategy(new MigrationFilenameParser(), strictRisk, defaultRisk),
                new PostgresSqlValidationStrategy(new PostgresMigrationStrategy(locator))
        ));

        MigrationValidationServiceImpl service = new MigrationValidationServiceImpl(locator, validationStrategyFactory, adapterFactory);
        var issues = service.validateTarget(target(), false);

        assertEquals(1, issues.stream().filter(issue -> issue.severity() == IssueSeverity.ERROR).count());
    }

    private Resource resource(String filename, String sql) {
        return new ByteArrayResource(sql.getBytes(StandardCharsets.UTF_8)) {
            @Override
            public String getFilename() {
                return filename;
            }
        };
    }

    private MigrationTarget target() {
        return new MigrationTarget("dev", "generic-service", "postgres-main-dev", "postgres", "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, "0", false, "flyway_history_generic_service", Map.of());
    }
}
