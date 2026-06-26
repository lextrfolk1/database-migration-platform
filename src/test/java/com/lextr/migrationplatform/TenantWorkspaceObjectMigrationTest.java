package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TenantWorkspaceObjectMigrationTest {

    @Test
    void definesTenantWorkspaceObjectTableWithExpectedConstraintsAndIndex() throws IOException {
        String migrationSql = read("migrations/semantic-service/postgres/V2__tenant_workspaces_and_hierarchies.sql");

        assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS meta.tenant_workspace_object"));
        assertTrue(migrationSql.contains("REFERENCES meta.tenant_workspace (workspace_cd) ON DELETE CASCADE"));
        assertTrue(migrationSql.contains("CONSTRAINT uq_two UNIQUE (workspace_cd, schema_cd, object_cd)"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_two_workspace ON meta.tenant_workspace_object (workspace_cd)"));
        assertFalse(migrationSql.contains("meta.workspace_object"));
    }

    private static String read(String path) throws IOException {
        return new ClassPathResource(path).getContentAsString(StandardCharsets.UTF_8);
    }
}
