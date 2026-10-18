-- Register intelligence-service in the system service registry (calls lexie-ai and semantic-service)
INSERT INTO system_service_registry (service_id, secret_hash, scopes, enabled)
VALUES
    ('intelligence-service', 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=', 'ai.execute,semantic.read', true)
ON CONFLICT (service_id) DO UPDATE SET
    secret_hash = EXCLUDED.secret_hash,
    scopes = EXCLUDED.scopes,
    enabled = EXCLUDED.enabled,
    updated_at = CURRENT_TIMESTAMP;
