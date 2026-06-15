package com.lextr.migrationplatform.exception;

public class MigrationExecutionException extends MigrationPlatformException {

    public MigrationExecutionException(String message) {
        super(message);
    }

    public MigrationExecutionException(String message, Throwable cause) {
        super(message, cause);
    }
}
