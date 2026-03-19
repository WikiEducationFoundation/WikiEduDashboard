The files in this directory serve to back up and document Wiki Education
Foundation's server configuration. These are not part of the dashboard itself,
and would need to be configured for any new production server.

## Webserver

These files are the main web server configuration files:
* `apache2.conf`
* `passenger.load` # apache passenger module in `etc/apache2/mods-available`
* `dashboard.conf` # apache config for dashboard.wikiedu.org (ie, production)
* `dashboard-testing.conf` # apache config for dashboard-testing.wikiedu.org (ie, staging)

## Database backup

We've designed a system to perform automatic database backups periodically
using the `sidekiq-status` gem.
The main idea behind this system is to have a backup script running on the DB servers
that interacts with the web-app to determine when it's a good time to run the backup,
since we don't want to run a backup while long DB transactions are in progress. The
script interacts with the web-app through the `can_start_backup.json` endpoint and by
creating backup records in the DB.


### Backup script

Both peony and wiki-edu-dashboard DB servers have the `backup.sh` script running
periodically under a cron job. The script takes cares of the following tasks:

- **Pre-backup tasks**: check there is enough free space, create backup folder for today,
create *waiting* backup record, wait until all pertinent jobs are sleeping, update the
backup record to running.

- **Backup tasks**: run the backup through the mariadb-dump command.

- **Post backup tasks**: update the backup record to *finished* and automatically delete
the oldest backup folder if there are more than three backups.

### Intended flow
- Weekly, a cron job runs on the db server, in charge of performing the backup
itself. The first task it performs is creating a new backup record with status
set to *waiting*. This works as a way to let the backend app knowing that a
backup is waiting to run.
- From this point, all CourseDataUpdateWorker jobs that start the UpdateCourseStats
in the background will be paused sleeping until the backup record leaves the *waiting*/*running*
status. Already running CourseDataUpdateWorker jobs will continue until completion.
- Some minutes later, the script running on the db server checks the `can_start_backup.json`
endpoint to determine whether it's safe to start the backup. The criterion is that a backup
can only run if all currently running CourseDataUpdateWorker jobs are in sleeping phase. If
the response is 503 server unavailable, it waits for 2 minutes and retries until it receives
a 200 OK response. Once it gets the 200 OK response, it sets the backup status to *running*.
- The backup script runs the backup itself.	
- Once the backup finishes, the backup script updates the data table record status to *finished*.
- CourseDataUpdateWorker jobs leaves the sleeping phase and woke up. The application returns
to normal operation.

### Installation

To enable automatic backups, we did the following in peony db server and wiki edu server:
1. Create a system linux user called *dbbackup*.
2. Add a sql user for it and grant the following permissions:

    ```
    CREATE USER 'dbbackup'@'localhost' IDENTIFIED VIA unix_socket;

    GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES ON dashboard.* TO 'dbbackup'@'localhost';

    GRANT INSERT, SELECT, UPDATE ON dashboard.backups TO 'dbbackup'@'localhost';
    ```
3. Copy the script and queries to the server at ``/home/dbbackup/backup.sh``.
4. Ensure *dbbackup* user is the owner of the script and it has execution permission.
4. Update the script with the correct values for ``BACKUP_ROUTE``, ``QUERY_ROUTE`` and ``DASHBOARD_URL``. For the wiki-edu server the ``BACKUP_ROUTE`` is ``/home/dbbackup/dumps``. For peony server, it's ``/srv/dumps``. Note that the cinder volume is mounted on ``/srv``, so that's where we have free space.
5. Add a cronjob to run the script weekly: run ``sudo crontab -u dbbackup -e`` and add ``0 20 * * SUN /home/dbbackup/backup.sh`` to the crontab.
