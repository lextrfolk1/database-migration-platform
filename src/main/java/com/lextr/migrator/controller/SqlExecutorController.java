package com.lextr.migrator.controller;

import com.lextr.migrator.service.SqlExecutionService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sql")
public class SqlExecutorController {

    private final SqlExecutionService sqlExecutionService;

    public SqlExecutorController(SqlExecutionService sqlExecutionService) {
        this.sqlExecutionService = sqlExecutionService;
    }

    @PostMapping("/run")
    public String runSqlScripts() {
        return sqlExecutionService.executeAllScripts();
    }
}
