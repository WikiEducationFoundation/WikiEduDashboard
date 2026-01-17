USE dashboard;

UPDATE backups
SET status = 'running', start = NOW()
WHERE status = 'waiting';
