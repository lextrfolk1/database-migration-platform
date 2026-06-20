package com.lextr.migrationplatform.service;

import com.lextr.migrationplatform.dto.MigrationHistoryResponse;

import java.util.List;

public interface MigrationHistoryService {

    List<MigrationHistoryResponse> history();

    MigrationHistoryResponse status(String executionId);
}
