package com.lextr.migrationplatform.repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lextr.migrationplatform.config.MigrationPlatformProperties;
import com.lextr.migrationplatform.entity.MigrationAuditEntity;
import com.lextr.migrationplatform.exception.MigrationPlatformException;
import org.springframework.stereotype.Repository;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

@Repository
public class AuditFileRepository {

    private final Path auditFile;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    public AuditFileRepository(MigrationPlatformProperties properties) {
        this.auditFile = Path.of(properties.getAuditDirectory(), "executions.json");
    }

    public synchronized void writeAll(List<MigrationAuditEntity> entities) {
        try {
            Files.createDirectories(auditFile.getParent());
            objectMapper.writerWithDefaultPrettyPrinter().writeValue(auditFile.toFile(), entities);
        } catch (IOException exception) {
            throw new MigrationPlatformException("Unable to persist audit record", exception);
        }
    }

    public synchronized List<MigrationAuditEntity> readAll() {
        if (!Files.exists(auditFile)) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(auditFile.toFile(), new TypeReference<>() {
            });
        } catch (IOException exception) {
            throw new MigrationPlatformException("Unable to read audit records", exception);
        }
    }
}
