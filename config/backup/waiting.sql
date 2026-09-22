USE dashboard;

-- Backups run weekly, so a waiting/running row older than 6 days is an orphan left
-- behind by a backup.sh that died without cleaning up (OOM, host restart). Fail it
-- first, otherwise it would keep the NOT EXISTS below from ever inserting a new row.
UPDATE backups
SET status = 'failed', end = NOW()
WHERE status IN ('waiting', 'running')
  AND created_at < NOW() - INTERVAL 6 DAY;

INSERT INTO backups (scheduled_at, status, created_at, updated_at)
SELECT NOW(), 'waiting', NOW(), NOW()
        WHERE NOT EXISTS (SELECT * FROM backups
                             WHERE status in ('waiting', 'running'));
