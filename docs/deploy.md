[Back to README](../README.md)

## Deploy

For deployment, the Dashboard uses [Capistrano](https://en.wikipedia.org/wiki/Capistrano_%28software%29). This requires authentication with the server via SSH.

The standard deployment process is as follows:

1. Work through the [contributing checklist](contributing.md)
2. Push/merge updates to the master branch in the repository (Github)
3. If your code includes a migration you must pause CRON jobs on your target server in order to prevent database block. Run the following task and wait long enough to allow any existing updates to end. (As of October 2016, updates take a little more than 2 hours.)

		$ cap <staging or production or wmflabs> sake task="batch:pause"

4. Deploy to the intended server, using the corresponding branch: production (dashboard.wikiedu.org), staging (dashboard-testing.wikiedu.org), or wmflabs (outreachdashboard.wmflabs.org)
    * staging and production can be automatically deployed via travis-ci. Merge master into production or staging, push to github, and CI server will attempt to deploy after a successful run of the unit tests.
    * wmflabs is deployed manually (and other branches can be as well, if needed):

  	  	  $ cap <wmflabs or staging or production> deploy

5. If you paused CRON jobs before deployment, unpause them when you're done:

		$ cap <staging or production or wmflabs> sake task="batch:resume"
6. If your changes include code that runs through Sidekiq, you may need to manually restart the relevant Sidekiq queue to ensure the new code is properly loaded. We've encountered errors related to this in the past.

		$ sudo systemctl restart <sidekiq-queue>

## Running rake tasks remotely

To run rake tasks on a server via Capistrano, use "sake":

	$ cap production sake task="batch:pause"

Note: batch updates can take a while, so you probably don't want to do them live via Capistrano.

## Set up a new production server

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](./WMFLABS_DEPLOYMENT.md).

## Recovery procedure

1. Set up a new production server. Production apache conf and sanitized application.yml are checked in to this repo.
2. Import SSL certs using sslmate.
3. Create a new OAuth consumer on meta.wikimedia.org and ping a WMF developer to get it approved quickly. Add tokens to application.yml
4. Import the lastest database backup. Recent backups are stored on the production server and also on wikiedubackups.globaleducation.eqiad.wmflabs (a virtual server on wmflabs.org).
