package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.dto.MigrationHistoryResponse;
import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.mapper.AuditResponseMapper;
import com.lextr.migrationplatform.service.AuditService;
import com.lextr.migrationplatform.service.MigrationHistoryService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MigrationHistoryServiceImpl implements MigrationHistoryService {

    private final AuditService auditService;
    private final AuditResponseMapper auditResponseMapper;

    public MigrationHistoryServiceImpl(AuditService auditService, AuditResponseMapper auditResponseMapper) {
        this.auditService = auditService;
        this.auditResponseMapper = auditResponseMapper;
    }

    @Override
    public List<MigrationHistoryResponse> history() {
        return auditService.findAll().stream()
                .map(auditResponseMapper::toResponse)
                .toList();
    }

    @Override
    public MigrationHistoryResponse status(String executionId) {
        return auditService.findByExecutionId(executionId)
                .map(auditResponseMapper::toResponse)
                .orElseThrow(() -> new ServiceNotFoundException("Unknown execution id: " + executionId));
    }
}
