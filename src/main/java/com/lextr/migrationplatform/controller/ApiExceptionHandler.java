package com.lextr.migrationplatform.controller;

import com.lextr.migrationplatform.dto.ErrorResponse;
import com.lextr.migrationplatform.exception.MigrationExecutionException;
import com.lextr.migrationplatform.exception.MigrationPlatformException;
import com.lextr.migrationplatform.exception.MigrationValidationException;
import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.exception.UnsupportedDatabaseException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler({ServiceNotFoundException.class, UnsupportedDatabaseException.class, MigrationValidationException.class, IllegalArgumentException.class})
    public ResponseEntity<ErrorResponse> handleBadRequest(Exception exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(Instant.now(), "BAD_REQUEST", exception.getMessage()));
    }

    @ExceptionHandler({MigrationExecutionException.class, IllegalStateException.class})
    public ResponseEntity<ErrorResponse> handleConflict(Exception exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse(Instant.now(), "CONFLICT", exception.getMessage()));
    }

    @ExceptionHandler(MigrationPlatformException.class)
    public ResponseEntity<ErrorResponse> handlePlatformException(MigrationPlatformException exception) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(Instant.now(), "PLATFORM_ERROR", exception.getMessage()));
    }
}
