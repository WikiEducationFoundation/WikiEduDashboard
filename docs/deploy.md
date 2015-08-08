[Back to README](../README.md)

For deployment, the Dashboard uses [Capistrano](https://en.wikipedia.org/wiki/Capistrano_%28software%29). This requires authentication with the server via SSH.

## Prepare for deployment
Assets should be rebuilt before deployment. It's easy to accidentally ship a build with out-of-date assets. To be sure you've got everything in order, you may need to do the following before you push a build for deployment:
- run `bundle install` to update gems
- run `npm install` to update Node packages
- run `bower install` to update other packages
- run `rake i18n:js:export` to rebuild i18n javascripts
- run `gulp build` to rebuild and minify fingerprinted assets

If there are new migrations since the last deployment, you should pause the batch updates and wait for any in-progress update to finish before you deploy. Otherwise, Capistrano may get stuck because the database is blocked for migration due to ongoing cache updates.
- Staging: `cap staging sake task=batch:pause`
- Production: `cap production sake task=batch:pause`

## Deploy

After pushing updates to repo (on Github), run the following command(s)
- Staging: `cap staging deploy` (This will deploy from the "master" branch)
- Production: `cap production deploy` (This will deploy from "production" branch)

If you paused batch updates before deployment, unpause them after deployment:
- Staging: `cap staging sake task=batch:resume`
- Production: `cap production sake task=batch:resume`

## On-demand rake tasks

To run rake tasks on a server via Capistrano, use "sake":
- $ `cap production sake task="batch:update_constantly"`
 - Note: batch updates can take a while, so you probably don't want to do them live over Capistrano.

## Set up a new production server

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](WMFLABS_DEPLOYMENT.md).
