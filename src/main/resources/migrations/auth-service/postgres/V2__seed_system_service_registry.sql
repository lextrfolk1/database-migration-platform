-- Seed system service registry with platform microservices and default scopes
INSERT INTO system_service_registry (service_id, secret_hash, scopes, enabled)
VALUES
    ('workflow-service', 'Cx7cVPXsSFBsNjiDDyTufEgBdCnLZJGR6vST4KqSbBU=', 'workflow.execute,workflow.status', true),
    ('analytics-service', 'M+6DKPQnXbPpxqwKb9hrG9+E4INxrGpXVSS5bstikis=', 'analytics.read,analytics.report', true),
    ('auth-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'auth.token,auth.validate', true),
    ('rules-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'rules.execute,rules.read,semantic.read,workflow.execute,execution.execute', true),
    ('workbench-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'workbench.read,workbench.write,rules.execute,virusscan.scan,workflow.execute', true),
    ('supplemental-upload', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'su.execute,data.sync,semantic.read,virusscan.scan,workflow.execute', true),
    ('su-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'su.execute,data.sync,semantic.read,virusscan.scan,workflow.execute', true),
    ('semantic-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'semantic.read,semantic.write,workflow.execute,workflow.status', true),
    ('reportgeneration-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'report.generate,workbench.read,workflow.execute', true),
    ('generic-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'generic.execute,virusscan.scan', true),
    ('data-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'data.execute,su.callback', true),
    ('execution-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'execution.execute,rules.read,workbench.read,semantic.read', true),
    ('lexie-ai', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'ai.execute,rules.read,execution.execute,semantic.read', true)
ON CONFLICT (service_id) DO UPDATE SET
    secret_hash = EXCLUDED.secret_hash,
    scopes = EXCLUDED.scopes,
    enabled = EXCLUDED.enabled,
    updated_at = CURRENT_TIMESTAMP;
