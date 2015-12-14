The files in this directory serve to back up and document Wiki Education
Foundation's server configuration. These are not part of the dashboard itself,
and would need to be configured for any new production server.

## Webserver

These files are the main web server configuration files:
* `apache2.conf`
* `dashboard.conf` # apache config for dashboard.wikiedu.org (ie, production)
* `dashboard-testing.conf` # apache config for dashboard-testing.wikiedu.org (ie, staging)

## Database backup script

For database backups, we use automysqlbackup: https://github.com/rcruz/AutoMySQLBackup

The backups get saved and rotated locally — this requires several GB of disk space.

The config file for our usage is included in the automysqlbackup directory. The
`runmysqlbackup` script also performs an rsync to save the backup files remotely.
This is the corresponding cron entry:

`05 * * * * /bin/bash -l -c 'sudo /etc/automysqlbackup/runmysqlbackup >> /var/log/mysqlbackup_cron_output'`
