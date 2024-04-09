## Capistrano deployments

* `rails c -e production` from the `/current` deployment directory doesn't work.
  * Install binstubs: `bundle install --binstubs`.

* Capistrano cannot restart sidekiq processes because the deploying user lacks passwordless sudo.
  * Configure that user for passwordless sudo:
    * Edit `/etc/sudoers`
    * add `deploying_user ALL=(ALL) NOPASSWD: ALL` at the end


## WMFLABS database disk space

* Open a ticket to increase storage allocation, like this: https://phabricator.wikimedia.org/T324694
* Once allocated, drain the sidekiq queues, put up a maintenance message on the Dashboard, then extend the volume:
  * find the instance on horizon.wikimedia.org
  * detach the cinder volume
  * follow directions here to resize the Cinder volume: https://wikitech.wikimedia.org/wiki/Help:Adding_Disk_Space_to_Cloud_VPS_instances#Cinder
  * reattach the Cinder volume. It should be /dev/sdb. If it's mounted somewhere else, restart the instance.
  * after resizing, restart all sidekiq services and remove the maintenance message

## Jobs rejected from redis queue by uniquejobs

Sometimes the redis entry for a job lock remains even though the job is not enqueued or runnings. Use `redis-cli` to interact with redis directly.

It's usually okay to delete all the locks by removing all uniquejobs keys. If there are no running jobs and the queues are empty, this is unlikely to cause problems. This will not interfere with scheduled jobs that haven't been enqueue yet.

* Useful commands:
  * Delete all uniquejobs keys: `redis-cli --raw keys "uniquejobs*" | xargs redis-cli del`
  * List all uniquejobs keys within redis-cli: `keys uniquejobs*`