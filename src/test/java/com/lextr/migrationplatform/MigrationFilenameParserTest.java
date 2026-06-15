package com.lextr.migrationplatform;

import com.lextr.migrationplatform.model.MigrationKind;
import com.lextr.migrationplatform.validation.MigrationFilenameParser;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class MigrationFilenameParserTest {

    private final MigrationFilenameParser parser = new MigrationFilenameParser();

    @Test
    void parsesVersionedMigration() {
        var parsed = parser.parse("V001__create_table.sql");
        assertEquals(MigrationKind.VERSIONED, parsed.kind());
        assertEquals("001", parsed.version());
        assertEquals("create_table", parsed.description());
    }

    @Test
    void parsesRepeatableMigration() {
        var parsed = parser.parse("R__refresh_view.sql");
        assertEquals(MigrationKind.REPEATABLE, parsed.kind());
        assertNull(parsed.version());
        assertEquals("refresh_view", parsed.description());
    }

    @Test
    void rejectsInvalidFilename() {
        assertThrows(IllegalArgumentException.class, () -> parser.parse("bad-name.sql"));
    }
}
