package com.lextr.migrator.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.io.IOException;
import java.sql.Connection;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SqlExecutionService {

    private final DataSource dataSource;
    private final Resource[] scriptResources;
    private final Set<String> excludedFiles;

    public SqlExecutionService(
            DataSource dataSource,
            @Value("${scripts.locations}") Resource[] scriptResources,
            @Value("${scripts.exclusions:}") String[] excludedFilesArray) {
        this.dataSource = dataSource;
        this.scriptResources = scriptResources;
        this.excludedFiles = new HashSet<>(Arrays.asList(excludedFilesArray));
    }

    @Transactional
    public String executeScriptsByDirectory() {
        try (Connection connection = dataSource.getConnection()) {

            // Group by parent directory path
            Map<String, List<Resource>> groupedByDirectory = Arrays.stream(scriptResources)
                    .filter(Resource::exists)
                    .filter(resource -> !excludedFiles.contains(resource.getFilename()))
                    .collect(Collectors.groupingBy(this::getParentDirectorySafe));

            // Sort directories
            List<String> sortedDirectories = new ArrayList<>(groupedByDirectory.keySet());
            Collections.sort(sortedDirectories);

            for (String dir : sortedDirectories) {
                System.out.println("== Executing scripts in directory: " + dir);

                groupedByDirectory.get(dir).stream()
                        .sorted(Comparator.comparing(Resource::getFilename, Comparator.nullsLast(String::compareTo)))
                        .forEach(resource -> {
                            try {
                                if (resource.contentLength() > 0) {
                                    ScriptUtils.executeSqlScript(connection, resource);
                                    System.out.println("Executed: " + resource.getFilename());
                                } else {
                                    System.out.println("Skipped empty script: " + resource.getFilename());
                                }
                            } catch (Exception e) {
                                throw new RuntimeException("Failed at script: " + resource.getFilename(), e);
                            }
                        });
            }

        } catch (Exception ex) {
            throw new RuntimeException("Script execution failed", ex);
        }

        return "All scripts executed directory by directory.";
    }

    private String getParentDirectorySafe(Resource resource) {
        try {
            String path = resource.getURL().getPath();
            return path.substring(0, path.lastIndexOf('/'));
        } catch (IOException e) {
            return "unknown";
        }
    }
}
