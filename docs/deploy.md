[Back to README](../README.md)

## Deploy

For deployment, the Dashboard uses [Capistrano](https://en.wikipedia.org/wiki/Capistrano_%28software%29). This requires authentication with the server via SSH.

The standard deployment process is as follows:

1. Work through the [pre-push checklist](contributing.md#pre-push-checklist)
2. Push updates to the repository (Github)
3. If your code includes a migration you must pause CRON jobs on your target server in order to prevent database block. Run the following task and wait 30 minutes to allow any existing updates to end.
		
		$ cap <staging or production> sake task="batch:pause"
	
3. Deploy to either "staging" (from the "master" branch) or "production" (from the "production" branch)

		$ cap <staging or production> deploy
		
4. If you paused CRON jobs before deployment, unpause them when you're done:

		$ cap <staging or production> sake task="batch:resume"

## Running rake tasks remotely

To run rake tasks on a server via Capistrano, use "sake":

	$ cap production sake task="batch:update_constantly"
	
Note: batch updates can take a while, so you probably don't want to do them live via Capistrano.
	
## Set up a new production server

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](./WMFLABS_DEPLOYMENT.md).

## Recovery procedure

1. Set up a new production server. Production apache conf and sanitized application.yml are checked in to this repo.
2. Import SSL certs using sslmate.
3. Create a new OAuth consumer on meta.wikimedia.org and ping a WMF developer to get it approved quickly. Add tokens to application.yml
4. Import the lastest database backup. Recent backups are stored on the production server and also on wikiedubackups.globaleducation.eqiad.wmflabs (a virtual server on wmflabs.org).
