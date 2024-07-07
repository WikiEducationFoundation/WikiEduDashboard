These are notes from setting up a separate Redis server, July 1, 2024.

* create a small instance (1 core, 2GB ram)
* ssh in
* sudo apt update
* sudo apt install redis-server

- Configure Redis to allow connections from other servers by editing `/etc/redis/redis.conf`
  - Comment out the `bind` setting to allow connections from all interfaces
  - Find the `protected-mode yes` line and change it to `protected-mode no`
  - `sudo service redis restart`

- Copy the dump.rdb file from a prior redis server
  - Find it in /var/lib/redis/ on old server
  - Stop new redis server
  - Delete unused dump.rdb from new server at /var/lib/redis/
  - Copy it into place on the new server, then `chown redis:redis dump.rdb`
  - Restart redis server
  
- Add the ENV entry to the application.yml of all servers: `REDIS_URL: 'redis://p-and-e-dashboard-redis'`
  - Alternative: Update all the sidekiq service files that are not on the webserver to use the new server
    - Add the Redis URL to the `[Service]` block, something like: `Environment=REDIS_URL=redis://p-and-e-dashboard-redis`

- Redeploy the webserver and restart all other sidekiq services, and check that the new server is working.
- Stop the old redis server