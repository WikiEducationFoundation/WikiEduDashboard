USE dashboard;

UPDATE backups
SET status = 'finished', end = NOW()
WHERE status = 'running';
