package com.lextr.migrator.platform.validation;

import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

@Component
public class SqlRiskScanner {

    private static final List<RiskPattern> RISK_PATTERNS = List.of(
            new RiskPattern("DROP_DATABASE", Pattern.compile("(?i)\\bDROP\\s+DATABASE\\b"), "Detected DROP DATABASE"),
            new RiskPattern("DROP_SCHEMA", Pattern.compile("(?i)\\bDROP\\s+SCHEMA\\b"), "Detected DROP SCHEMA"),
            new RiskPattern("TRUNCATE", Pattern.compile("(?i)\\bTRUNCATE\\b"), "Detected TRUNCATE"),
            new RiskPattern("DELETE_ALL", Pattern.compile("(?im)^\\s*DELETE\\s+FROM\\s+[^;]+;\\s*$"), "Detected DELETE FROM ...; without a WHERE clause"),
            new RiskPattern("ALTER_COLUMN_TYPE", Pattern.compile("(?i)\\bALTER\\s+(TABLE\\s+\\S+\\s+)?ALTER\\s+COLUMN\\s+\\S+\\s+TYPE\\b"), "Detected ALTER COLUMN TYPE"),
            new RiskPattern("DROP_COLUMN", Pattern.compile("(?i)\\bDROP\\s+COLUMN\\b"), "Detected DROP COLUMN"),
            new RiskPattern("RENAME_COLUMN", Pattern.compile("(?i)\\bRENAME\\s+COLUMN\\b"), "Detected RENAME COLUMN")
    );

    public List<ValidationIssue> scan(Resource resource) {
        String sql = read(resource);
        List<ValidationIssue> issues = new ArrayList<>();
        for (RiskPattern riskPattern : RISK_PATTERNS) {
            if (riskPattern.pattern.matcher(sql).find()) {
                issues.add(new ValidationIssue(IssueSeverity.WARNING, riskPattern.code, riskPattern.message + " in " + resource.getFilename()));
            }
        }
        return issues;
    }

    private String read(Resource resource) {
        try {
            return new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to read SQL resource " + resource.getFilename(), exception);
        }
    }

    private record RiskPattern(String code, Pattern pattern, String message) {
    }
}
