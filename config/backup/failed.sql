USE dashboard;

UPDATE backups
SET status = 'failed', end = NOW()
WHERE status IN ('waiting', 'running');
