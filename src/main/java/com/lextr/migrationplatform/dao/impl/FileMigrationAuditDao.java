package com.lextr.migrationplatform.dao.impl;

import com.lextr.migrationplatform.dao.MigrationAuditDao;
import com.lextr.migrationplatform.entity.MigrationAuditEntity;
import com.lextr.migrationplatform.repository.AuditFileRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class FileMigrationAuditDao implements MigrationAuditDao {

    private final AuditFileRepository auditFileRepository;

    public FileMigrationAuditDao(AuditFileRepository auditFileRepository) {
        this.auditFileRepository = auditFileRepository;
    }

    @Override
    public synchronized void save(MigrationAuditEntity entity) {
        List<MigrationAuditEntity> entities = auditFileRepository.readAll();
        entities.removeIf(existing -> existing.executionId().equals(entity.executionId()));
        entities.add(entity);
        auditFileRepository.writeAll(entities);
    }

    @Override
    public synchronized List<MigrationAuditEntity> findAll() {
        return List.copyOf(auditFileRepository.readAll());
    }

    @Override
    public synchronized Optional<MigrationAuditEntity> findByExecutionId(String executionId) {
        return auditFileRepository.readAll().stream()
                .filter(entity -> entity.executionId().equals(executionId))
                .findFirst();
    }
}
