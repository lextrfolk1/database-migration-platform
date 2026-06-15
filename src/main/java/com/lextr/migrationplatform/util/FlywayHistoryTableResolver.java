package com.lextr.migrationplatform.util;

import com.lextr.migrationplatform.model.ServiceTargetMapping;
import com.lextr.migrationplatform.model.TargetDatabase;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Locale;

@Component
public class FlywayHistoryTableResolver {

    public String resolve(String serviceName, TargetDatabase targetDatabase, ServiceTargetMapping mapping) {
        if (mapping.historyTable() != null && !mapping.historyTable().isBlank()) {
            return mapping.historyTable();
        }
        String basePrefix = targetDatabase.historyTablePrefix() != null && !targetDatabase.historyTablePrefix().isBlank()
                ? targetDatabase.historyTablePrefix()
                : "flyway_history";
        String normalizedService = serviceName.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "_").replaceAll("^_+|_+$", "");
        String candidate = basePrefix + "_" + normalizedService;
        if (candidate.length() <= 63) {
            return candidate;
        }
        String digest = shortHash(serviceName);
        int keep = Math.max(10, 63 - basePrefix.length() - digest.length() - 2);
        String shortenedService = normalizedService.substring(0, Math.min(keep, normalizedService.length()));
        return basePrefix + "_" + shortenedService + "_" + digest;
    }

    private String shortHash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash, 0, 6);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 not available", exception);
        }
    }
}
