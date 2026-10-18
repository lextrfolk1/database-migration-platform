-- Align workflow-service and analytics-service with the shared dev service secret (jwt.service-secret in
-- config-service application.yml) so their system-token logins succeed; their previous secrets were not known.
UPDATE system_service_registry
SET secret_hash = 'TZ815BKt8DoNqTZgdAPCo3DX4RvE19scwDVSkjbD6kc=',
    updated_at = CURRENT_TIMESTAMP
WHERE service_id IN ('workflow-service', 'analytics-service');
