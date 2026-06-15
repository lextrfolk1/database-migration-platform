package com.lextr.migrationplatform.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

public record MigrationActionRequest(
        String scope,
        String service,
        String target,
        @JsonAlias("database")
        String databaseType,
        String environment,
        String mode,
        @JsonAlias({"all_databases", "all_targets"})
        Boolean allTargets,
        @JsonAlias("continue_on_error")
        Boolean continueOnError,
        @JsonAlias("allow_risky")
        Boolean allowRisky,
        Boolean confirm,
        @JsonAlias("requested_by")
        String requestedBy
) {
}
