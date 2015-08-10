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

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](../WMFLABS_DEPLOYMENT.md).
