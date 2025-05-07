package com.lextr.migrator.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

@Service
public class SqlExecutionService {

    private final DataSource dataSource;
    private final Resource[] scriptResources;
    private final List<String> excludedFiles;

    public SqlExecutionService(DataSource dataSource, @Value("${scripts.locations}") Resource[] scriptResources,
                               @Value("${scripts.exclusions:}") String[] excludedFilesArray) {
        this.dataSource = dataSource;
        this.scriptResources = scriptResources;
        this.excludedFiles = Arrays.stream(excludedFilesArray).toList();
    }

    @Transactional
    public String executeAllScripts() {
        try (Connection connection = dataSource.getConnection()) {
            Arrays.stream(scriptResources)
                    .sorted(Comparator.comparing(Resource::getFilename))
                    .filter(resource ->  !excludedFiles.contains(resource.getFilename()))// sort by filename
                    .forEach(resource -> {
                        try {
                            if (resource.exists() && resource.contentLength() > 0) {
                                ScriptUtils.executeSqlScript(connection, resource);
                                System.out.println("Executed: " + resource.getFilename());
                            } else {
                                System.out.println("Skipped empty or missing script: " + resource.getFilename());
                            }
                        } catch (Exception e) {
                            throw new RuntimeException("Failed at " + resource.getFilename(), e);
                        }
                    });
        } catch (Exception ex) {
            throw new RuntimeException("Script execution failed", ex);
        }

        return "All scripts executed successfully.";
    }
}
