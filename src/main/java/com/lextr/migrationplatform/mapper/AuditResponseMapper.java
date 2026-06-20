package com.lextr.migrationplatform.mapper;

import com.lextr.migrationplatform.dto.MigrationHistoryResponse;
import com.lextr.migrationplatform.entity.MigrationAuditEntity;
import org.springframework.stereotype.Component;

@Component
public class AuditResponseMapper {

    public MigrationHistoryResponse toResponse(MigrationAuditEntity entity) {
        return new MigrationHistoryResponse(
                entity.executionId(),
                entity.scope(),
                entity.service(),
                entity.target(),
                entity.databaseType(),
                entity.environment(),
                entity.mode(),
                entity.requestedBy(),
                entity.startedAt(),
                entity.completedAt(),
                entity.status(),
                entity.executedMigrations(),
                entity.failedMigration(),
                entity.errorMessage(),
                entity.durationMs(),
                entity.riskOverrideUsed()
        );
    }
}
