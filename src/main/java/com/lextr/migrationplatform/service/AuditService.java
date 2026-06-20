package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.entity.MigrationAuditEntity;

import java.util.List;
import java.util.Optional;

public interface AuditService {

    void save(MigrationAuditEntity entity);

    List<MigrationAuditEntity> findAll();

    Optional<MigrationAuditEntity> findByExecutionId(String executionId);
}
