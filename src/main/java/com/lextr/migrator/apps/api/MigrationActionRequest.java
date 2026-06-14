package com.lextr.migrator.apps.api;

import com.fasterxml.jackson.annotation.JsonAlias;

public record MigrationActionRequest(
        String scope,
        String service,
        String database,
        String environment,
        String mode,
        @JsonAlias("all_databases")
        Boolean allDatabases,
        @JsonAlias("continue_on_error")
        Boolean continueOnError,
        @JsonAlias("allow_risky")
        Boolean allowRisky,
        Boolean confirm,
        @JsonAlias("requested_by")
        String requestedBy
) {
}
