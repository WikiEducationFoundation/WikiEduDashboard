[Back to README](../README.md)

---

## Deploy

For deployment, the Dashboard uses [Capistrano](https://en.wikipedia.org/wiki/Capistrano_%28software%29). This requires authentication with the server via SSH.

After pushing updates to repo (on Github), run the following command(s)
- Staging: `cap staging deploy` (This will deploy from the "master" branch)
- Production: `cap production deploy` (This will deploy from "production" branch)

To run rake tasks on a server via Capistrano, use "sake":
- $ `cap production sake task="batch:update_constantly"`

## Set up a new production server

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](WMFLABS_DEPLOYMENT.md).
