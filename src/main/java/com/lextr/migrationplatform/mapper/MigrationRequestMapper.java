package com.lextr.migrationplatform.mapper;

import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.dto.MigrationActionRequest;
import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.RunMode;
import org.springframework.stereotype.Component;

@Component
public class MigrationRequestMapper {

    private final MigrationPlatformProperties properties;

    public MigrationRequestMapper(MigrationPlatformProperties properties) {
        this.properties = properties;
    }

    public MigrationRequest toModel(MigrationActionRequest request, RunMode fallbackMode) {
        ExecutionScope scope = request.scope() != null && request.scope().equalsIgnoreCase("all-services")
                ? ExecutionScope.ALL_SERVICES
                : ExecutionScope.SERVICE;
        RunMode mode = request.mode() == null ? fallbackMode : RunMode.valueOf(request.mode().toUpperCase());
        return new MigrationRequest(
                scope,
                request.service(),
                request.target(),
                request.databaseType(),
                request.environment(),
                Boolean.TRUE.equals(request.allTargets()),
                mode,
                Boolean.TRUE.equals(request.continueOnError()),
                Boolean.TRUE.equals(request.allowRisky()),
                Boolean.TRUE.equals(request.confirm()),
                request.requestedBy() == null || request.requestedBy().isBlank() ? properties.getDefaultRequestedBy() : request.requestedBy()
        );
    }
}
