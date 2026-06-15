package com.lextr.migrationplatform.strategy;

import com.lextr.migrationplatform.model.ValidationIssue;
import org.springframework.core.io.Resource;

import java.util.List;

public interface RiskDetectionStrategy {

    List<ValidationIssue> detect(Resource resource);
}
