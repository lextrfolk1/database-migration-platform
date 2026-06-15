package com.lextr.migrationplatform;

import com.lextr.migrationplatform.config.MigrationPlatformInventoryConfiguration;
import com.lextr.migrationplatform.dao.impl.DefaultServiceInventoryDao;
import com.lextr.migrationplatform.repository.PlatformConfigurationRepository;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ServiceInventoryDaoTest {

    @Test
    void loadsSharedTargetConfigurationOnceAndLetsServicesReferenceIt() {
        PlatformConfigurationRepository repository = mock(PlatformConfigurationRepository.class);
        when(repository.load()).thenReturn(new MigrationPlatformInventoryConfiguration(
                "dev",
                Map.of(),
                Map.of(
                        "postgres-main-dev", new MigrationPlatformInventoryConfiguration.TargetDatabaseConfig(
                                "postgres", "dev", "jdbc:postgresql://localhost:5432/app",
                                "app_user", null, "CUSTOMER_PW", "public", List.of(),
                                true, "0", false, null, "flyway_history", Map.of()
                        )
                ),
                Map.of(
                        "generic-service", new MigrationPlatformInventoryConfiguration.ServiceMigrationConfig(List.of(
                                new MigrationPlatformInventoryConfiguration.MigrationLocationConfig(
                                        "postgres-main-dev", List.of("classpath:migrations/generic-service/postgres"),
                                        null, List.of("acct"), null, Map.of()
                                )
                        ))
                )
        ));

        DefaultServiceInventoryDao dao = new DefaultServiceInventoryDao(repository, new MockEnvironment().withProperty("CUSTOMER_PW", "secret"));
        var snapshot = dao.loadInventory();

        assertEquals(1, snapshot.targets().size());
        assertEquals(1, snapshot.services().size());
        assertEquals("secret", snapshot.targets().get("postgres-main-dev").password());
        assertEquals("postgres-main-dev", snapshot.services().get("generic-service").targetMappings().get(0).targetName());
    }
}
