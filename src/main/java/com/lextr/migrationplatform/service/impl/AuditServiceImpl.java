package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.dao.MigrationAuditDao;
import com.lextr.migrationplatform.entity.MigrationAuditEntity;
import com.lextr.migrationplatform.service.AuditService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AuditServiceImpl implements AuditService {

    private final MigrationAuditDao migrationAuditDao;

    public AuditServiceImpl(MigrationAuditDao migrationAuditDao) {
        this.migrationAuditDao = migrationAuditDao;
    }

    @Override
    public void save(MigrationAuditEntity entity) {
        migrationAuditDao.save(entity);
    }

    @Override
    public List<MigrationAuditEntity> findAll() {
        return migrationAuditDao.findAll();
    }

    @Override
    public Optional<MigrationAuditEntity> findByExecutionId(String executionId) {
        return migrationAuditDao.findByExecutionId(executionId);
    }
}
