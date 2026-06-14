package com.lextr.migrator.platform.validation;

import org.springframework.stereotype.Component;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class MigrationFilenameParser {

    private static final Pattern VERSIONED_PATTERN = Pattern.compile("^(V|U|B)(\\d+)__([A-Za-z0-9_\\-]+)\\.sql$");
    private static final Pattern REPEATABLE_PATTERN = Pattern.compile("^R__([A-Za-z0-9_\\-]+)\\.sql$");

    public ParsedMigrationFilename parse(String filename) {
        Matcher versionedMatcher = VERSIONED_PATTERN.matcher(filename);
        if (versionedMatcher.matches()) {
            return new ParsedMigrationFilename(
                    switch (versionedMatcher.group(1)) {
                        case "V" -> MigrationKind.VERSIONED;
                        case "U" -> MigrationKind.UNDO;
                        case "B" -> MigrationKind.BASELINE;
                        default -> throw new IllegalArgumentException("Unsupported migration prefix in " + filename);
                    },
                    versionedMatcher.group(2),
                    versionedMatcher.group(3)
            );
        }

        Matcher repeatableMatcher = REPEATABLE_PATTERN.matcher(filename);
        if (repeatableMatcher.matches()) {
            return new ParsedMigrationFilename(MigrationKind.REPEATABLE, null, repeatableMatcher.group(1));
        }

        throw new IllegalArgumentException("Invalid migration filename: " + filename);
    }
}
