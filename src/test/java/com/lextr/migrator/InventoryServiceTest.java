package com.lextr.migrator;

import com.lextr.migrator.platform.config.PlatformConfigLoader;
import com.lextr.migrator.platform.config.PlatformConfiguration;
import com.lextr.migrator.platform.inventory.InventoryService;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class InventoryServiceTest {

    @Test
    void loadsConfiguredTargets() {
        PlatformConfigLoader loader = mock(PlatformConfigLoader.class);
        when(loader.load()).thenReturn(new PlatformConfiguration("dev", Map.of(
                "dev", new PlatformConfiguration.EnvironmentDefinition(Map.of(
                        "customer-service", Map.of(
                                "postgres", new PlatformConfiguration.DatabaseDefinition(
                                        "jdbc:postgresql://localhost:5432/customer",
                                        "customer",
                                        null,
                                        "CUSTOMER_PW",
                                        List.of("classpath:migrations/customer-service/postgres"),
                                        List.of("public"),
                                        true,
                                        false,
                                        null,
                                        null,
                                        Map.of()
                                )
                        )
                ))
        )));

        MockEnvironment environment = new MockEnvironment().withProperty("CUSTOMER_PW", "secret");
        InventoryService service = new InventoryService(loader, environment);

        var targets = service.listTargets();
        assertEquals(1, targets.size());
        assertEquals("customer-service", targets.get(0).service());
        assertEquals("postgres", targets.get(0).database());
        assertEquals("secret", targets.get(0).password());
    }

    @Test
    void derivesLegacyTargetsFromSpringProperties() {
        PlatformConfigLoader loader = mock(PlatformConfigLoader.class);
        when(loader.load()).thenReturn(new PlatformConfiguration(null, Map.of()));

        MockEnvironment environment = new MockEnvironment()
                .withProperty("spring.datasource.url", "jdbc:postgresql://localhost:5432/legacy")
                .withProperty("spring.datasource.username", "postgres")
                .withProperty("spring.datasource.password", "admin")
                .withProperty("spring.flyway.locations",
                        "classpath:db/init/00_schema,classpath:db/init/01_generic_service,classpath:db/init/02_workflow_service")
                .withProperty("spring.flyway.schemas", "meta,data");

        InventoryService service = new InventoryService(loader, environment);

        var targets = service.listTargets();
        assertEquals(2, targets.size());
        assertEquals(List.of("classpath:db/init/00_schema", "classpath:db/init/01_generic_service"), targets.get(0).locations());
        assertEquals("legacy", targets.get(0).environment());
    }
}
