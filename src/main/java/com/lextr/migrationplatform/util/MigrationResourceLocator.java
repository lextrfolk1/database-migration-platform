package com.lextr.migrationplatform.util;

import com.lextr.migrationplatform.exception.MigrationPlatformException;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

@Component
public class MigrationResourceLocator {

    private final ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();

    public List<Resource> sqlResources(String location) {
        String normalized = location.endsWith("/") ? location + "*.sql" : location + "/*.sql";
        if (normalized.startsWith("classpath:")) {
            normalized = "classpath*:" + normalized.substring("classpath:".length());
        } else if (normalized.startsWith("filesystem:")) {
            normalized = "file:" + normalized.substring("filesystem:".length());
        }
        try {
            return Arrays.stream(resolver.getResources(normalized))
                    .sorted(Comparator.comparing(Resource::getFilename, Comparator.nullsLast(String::compareTo)))
                    .toList();
        } catch (IOException exception) {
            throw new MigrationPlatformException("Unable to read migration resources from " + location, exception);
        }
    }
}
