package com.lextr.migrator;

import com.lextr.migrator.integrations.databases.base.DatabaseIntegrationRegistry;
import com.lextr.migrator.platform.inventory.MigrationResourceLocator;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.validation.IssueSeverity;
import com.lextr.migrator.platform.validation.MigrationFilenameParser;
import com.lextr.migrator.platform.validation.MigrationValidationService;
import com.lextr.migrator.platform.validation.SqlRiskScanner;
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
        DatabaseIntegrationRegistry registry = mock(DatabaseIntegrationRegistry.class);
        when(registry.supports("postgres")).thenReturn(true);
        when(locator.sqlResources("classpath:test")).thenReturn(List.of(resource("V001__drop_table.sql", "TRUNCATE table_x;")));

        MigrationValidationService service = new MigrationValidationService(locator, new MigrationFilenameParser(), new SqlRiskScanner(), registry);
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
        return new MigrationTarget("dev", "customer-service", "postgres", "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, false, null, Map.of(), false);
    }
}
