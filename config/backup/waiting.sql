USE dashboard;

INSERT INTO backups (scheduled_at, status, created_at, updated_at)
SELECT NOW(), 'waiting', NOW(), NOW()
        WHERE NOT EXISTS (SELECT * FROM backups
                             WHERE status in ('waiting', 'running'));
