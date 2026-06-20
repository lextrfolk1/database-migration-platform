package com.lextr.migrationplatform.exception;

public class MigrationPlatformException extends RuntimeException {

    public MigrationPlatformException(String message) {
        super(message);
    }

    public MigrationPlatformException(String message, Throwable cause) {
        super(message, cause);
    }
}
