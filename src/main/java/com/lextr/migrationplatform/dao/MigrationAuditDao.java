package com.lextr.migrationplatform.dao;

import com.lextr.migrationplatform.entity.MigrationAuditEntity;

import java.util.List;
import java.util.Optional;

public interface MigrationAuditDao {

    void save(MigrationAuditEntity entity);

    List<MigrationAuditEntity> findAll();

    Optional<MigrationAuditEntity> findByExecutionId(String executionId);
}
