These are notes from setting up a fresh web server on the newest Debian, July 2, 2024.

## Prepare the data and create the instance

* Copy the contents of the `config` and `public` directories from `/var/www/dashboard/shared/` on the old web server.
  * `config` has the config files. `public` has the user profile pictures and any not-yet-deleted CSV files that users generated.

* Spin up a new instance on Horizon, with the `default` and `web` security groups.
  
## Prep the server

* Main requirements for the Dashboard webserver:
  * `sudo apt install pandoc libmariadb-dev imagemagick gnupg2 apache2 memcached shared-mime-info rsync`
* Passenger requirements:
  * `sudo apt install libcurl4-openssl-dev libapr1-dev libaprutil1-dev apache2-dev`

- Assign ownership to yourself for the web directory /var/www
  - $ `sudo chown <username> /var/www`

- Add swap. WMCloud instances have none by default, and a Rails server without swap has no cushion: once memory fills, the kernel can only reclaim page cache, so it thrashes indefinitely and the server stops making progress without ever triggering the OOM killer. Size the swapfile to fit the root disk with room to spare — a full root filesystem is worse than no swap.
  - $ `sudo fallocate -l 2G /swapfile`
  - $ `sudo chmod 600 /swapfile`
  - $ `sudo mkswap /swapfile`
  - $ `sudo swapon /swapfile`
  - $ `echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab`
  - $ `sudo systemctl daemon-reload`
  - Leave `vm.swappiness` at its default. The usual advice to lower it on servers is counterproductive here: cold worker heap is exactly what should be swappable, so that executable pages can stay resident.

## RVM, Passenger, Apache

- Install RVM (Ruby Version Manager) and configure the Dashboard's current Ruby version, as the deploying user
  - $ `gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB`
  - $ `\curl -sSL https://get.rvm.io | bash -s stable`
  - $ `source /home/ragesoss/.rvm/scripts/rvm`
  - logout and back in again so that these settings take effect
  - $ `rvm install 3.4.8`
  - $ `rvm --default use 3.4.8`

- Install Phusion Passenger module for Apache
  - $ `gem install passenger`
  - $ `rvmsudo passenger-install-apache2-module`
    - look out for errors or missing dependencies and follow all directions which likely include adding some code to the apache configuration, as follows...
  - $ `sudo nano /etc/apache2/apache2.conf`
  - Add to the end the text instructed by the passenger installer, something like:

```
  LoadModule passenger_module /home/ragesoss/.rvm/gems/ruby-3.4.8/gems/passenger-6.1.2/buildout/apache2/mod_passenger.so
  <IfModule mod_passenger.c>
    PassengerRoot /home/ragesoss/.rvm/gems/ruby-3.4.8/gems/passenger-6.1.2
    PassengerDefaultRuby /home/ragesoss/.rvm/gems/ruby-3.4.8/wrappers/ruby
    PassengerPreloadBundler on
  </IfModule>

```

  - within that Passenger block, add additional rules to configure the PIDs directory and to bound worker memory:
```
  PassengerInstanceRegistryDir /var/www/dashboard/shared/tmp/pids
  PassengerMaxPoolSize 4
  PassengerMaxRequests 1000
```
    - `PassengerMaxPoolSize` caps how many application processes run at once. Passenger's default is 6, which on a small VM can require more memory than the server has. Workers have been observed starting at ~265 MB and reaching ~1.6 GB after about three hours, so six mature workers would want ~9.7 GB. Choose a value such that (pool size × expected mature worker size) fits in RAM alongside Sidekiq and memcached.
    - `PassengerMaxRequests` recycles a worker after that many requests, reclaiming its memory before it bloats. Without this, worker memory only grows. Aim for recycling every 30–60 minutes under normal traffic, and lower the number if workers are still reaching a gigabyte.
    - Both settings were added after the incident in #6990, where their absence left the P&E Dashboard web server wedging every day or two.
- Limit glibc malloc arenas for the Ruby processes Apache spawns
  - $ `sudo nano /etc/apache2/envvars`
  - add at the end: `export MALLOC_ARENA_MAX=2`
  - This matches what every Sidekiq unit in `server_config/systemd` already sets, and reduces memory fragmentation in the Passenger workers. Apache must be fully restarted rather than reloaded for this to take effect, because the environment is inherited at process start: systemd runs `apachectl`, which sources `envvars`, and a graceful reload leaves the existing Apache master and Passenger core running with their original environment.
  - Verify it reached the workers rather than assuming: `pgrep -f "Passenger RubyApp" | head -1 | xargs -I{} sudo cat /proc/{}/environ | tr '\0' '\n' | grep MALLOC`

- Create a VirtualHost for the app
  - $ `sudo nano /etc/apache2/sites-available/dashboard.conf`
  - Add something like this:

```
<VirtualHost *:80>
  ServerAdmin sage@wikiedu.org
  DocumentRoot /var/www/dashboard/current/public
  RackEnv production
  <Directory /var/www/dashboard/current/public>
    AllowOverride all
    Options -MultiViews
  </Directory>
  ErrorLog /var/log/apache2/dashboard/error.log
  CustomLog /var/log/apache2/dashboard/access.log common
</VirtualHost>
```
  - $ `sudo mkdir /var/log/apache2/dashboard`
  - $ `sudo service apache2 restart`

- Increase the capacity of memcache
  - $ `sudo nano /etc/memcached.conf`
  - change the maximum size from 64m to 1024m: `-m 1024`
  - add a higher max item size (default 1m): `-I 5m`
  - $ `sudo service memcached restart`

## Deployment

- Update or create the corresponding deployment file (eg, '/config/deploy/peony.rb') to point to your new wmcloud instance (and commit the changes and push to github, once it works),
- Start the Capistrano deployment. Enter the app's directory, then:
  - $ `bundle exec cap peony deploy`
  - This is expected to fail because configuration files are not yet in place — in particular, application.yml, database.yml, and secrets.yml
   - If it fails but you don't get a message about one of those files, try it again.
- Copy the `config` and `public` directory contents on to the new server at the same location (`/var/www/dashboard/shared/`)
- Create the tmp directory for pid files
  - $ `mkdir /var/www/dashboard/shared/tmp/pids`
  - (Sidekiq will create a pid file in this directory upon deployment. If it is unable to do so, background jobs will not be performed.)

- Add systemd services for the app's sidekiq processes. Only the lightest queue belongs on the web server; the rest should be on separate Sidekiq servers.
  - `default` is light enough to share the web server, but note that it is load-bearing for the entire update pipeline: it runs `ScheduleCourseUpdatesWorker`, so if nothing is consuming the `default` queue, no course updates get scheduled on *any* server and every other Sidekiq host drains its queue and goes idle. When diagnosing a system-wide stall, check this first.
  - Do **not** run `daily` on the web server. It carries one of the heaviest jobs in the system — `ImportRatingsWorker`, which sweeps all articles — and has been observed at over 1 GB resident while competing with the web application for the same RAM. See #6990.
  - `constant` runs on a separate Sidekiq server in the current P&E Dashboard setup, notwithstanding what earlier versions of these notes said.
  - copy the .service files from `server_config/systemd` into the systemd directory ( `/etc/systemd/system` on Debian)
    - Change the user and group lines to match the user who owns the deployment process (and one of their groups)
  - enable each service: `systemctl enable sidekiq-default`, etc.

- Enable the site
  - $ `sudo a2dissite 000-default`
  - $ `sudo a2ensite dashboard`
  - $ `sudo systemctl reload apache2`
  - $ `sudo service apache2 restart`

- Deploy again with Capistrano:
  - $ `bundle exec cap peony deploy`