The files in this directory serve to back up and document Wiki Education
Foundation's server configuration. These are not part of the dashboard itself,
and would need to be configured for any new production server.

## Webserver

These files are the main web server configuration files:
* `apache2.conf`
* `passenger.load` # apache passenger module in `etc/apache2/mods-available`
* `dashboard.conf` # apache config for dashboard.wikiedu.org (ie, production)
* `dashboard-testing.conf` # apache config for dashboard-testing.wikiedu.org (ie, staging)

## Database backup script

TODO: complete
