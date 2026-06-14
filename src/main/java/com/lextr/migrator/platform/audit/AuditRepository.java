package com.lextr.migrator.platform.audit;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lextr.migrator.platform.config.PlatformProperties;
import org.springframework.stereotype.Repository;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
public class AuditRepository {

    private final Path auditFile;
    private final ObjectMapper objectMapper;

    public AuditRepository(PlatformProperties properties) {
        this.auditFile = Path.of(properties.getAuditDirectory(), "executions.json");
        this.objectMapper = new ObjectMapper().findAndRegisterModules();
    }

    public synchronized void save(AuditRecord record) {
        try {
            Files.createDirectories(auditFile.getParent());
            List<AuditRecord> records = findAllInternal();
            records.removeIf(existing -> existing.executionId().equals(record.executionId()));
            records.add(record);
            objectMapper.writerWithDefaultPrettyPrinter().writeValue(auditFile.toFile(), records);
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to persist audit record", exception);
        }
    }

    public synchronized List<AuditRecord> findAll() {
        return List.copyOf(findAllInternal());
    }

    public synchronized Optional<AuditRecord> findByExecutionId(String executionId) {
        return findAllInternal().stream()
                .filter(record -> record.executionId().equals(executionId))
                .findFirst();
    }

    private List<AuditRecord> findAllInternal() {
        if (!Files.exists(auditFile)) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(auditFile.toFile(), new TypeReference<>() {
            });
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to read audit records", exception);
        }
    }
}
