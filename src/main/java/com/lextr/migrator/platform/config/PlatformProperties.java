package com.lextr.migrator.platform.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "migration.platform")
public class PlatformProperties {

    private String configLocation = "classpath:migration-platform.yml";
    private String auditDirectory = "build/audit";
    private boolean allowProductionRebuild = false;
    private String defaultRequestedBy = "dba-operator";

    public String getConfigLocation() {
        return configLocation;
    }

    public void setConfigLocation(String configLocation) {
        this.configLocation = configLocation;
    }

    public String getAuditDirectory() {
        return auditDirectory;
    }

    public void setAuditDirectory(String auditDirectory) {
        this.auditDirectory = auditDirectory;
    }

    public boolean isAllowProductionRebuild() {
        return allowProductionRebuild;
    }

    public void setAllowProductionRebuild(boolean allowProductionRebuild) {
        this.allowProductionRebuild = allowProductionRebuild;
    }

    public String getDefaultRequestedBy() {
        return defaultRequestedBy;
    }

    public void setDefaultRequestedBy(String defaultRequestedBy) {
        this.defaultRequestedBy = defaultRequestedBy;
    }
}
