package com.lextr.migrationplatform.exception;

public class FlywayExecutionException extends MigrationExecutionException {

    public FlywayExecutionException(String message, Throwable cause) {
        super(message, cause);
    }
}
