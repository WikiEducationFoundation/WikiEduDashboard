ON WIKITECH
-------------

- On wikitech, join or create a project. Create a web security group, with ports 80 and 443 open.

- Create an instance on wikitech:
  - Security groups: default, web
  - For Programs & Events Dashboard production:
    - use an extra large instance
    - enable the full storage allocation by following these instructions: https://wikitech.wikimedia.org/wiki/Help:Adding_Disk_Space
    

- Create a web proxy for this new instance. This will determine the url of your dashboard (something like educationdashboard.wmflabs.org)

ON THE SERVER
-------------

- ssh into this new instance from your machine
  - You may may need to configure your SSH client for this new instance: https://wikitech.wikimedia.org/wiki/Help:Accessing_Cloud_VPS_instances

- install some additional packages needed by the app and web server
  - $ `sudo apt update`
  - $ `sudo apt install pandoc redis-server mariadb-server libmariadb-dev imagemagick gnupg2 apache2 memcached shared-mime-info`
- Passenger requirements:
  - $ `sudo apt install libcurl4-openssl-dev libapr1-dev libaprutil1-dev apache2-dev`

- (DATABASE NODE ONLY) configure mariaDB to use /srv as the location of database files:
  - `sudo systemctl stop mysql`
  - `sudo mv /var/lib/msyql /srv/mysql`
  - edit `/etc/mysql/my.conf` and add the following directives:
    ```
    [mysqld]
    datadir=/srv/mysql
    socket=/srv/mysql/mysql.sock

    [client]
    port=3306
    socket=/srv/mysql/mysql.sock
    ```
  - verify that the new data directory is set, by logging into mysql and doing `select @@datadir;`

- (DATABASE NODE ONLY)  Create a database for the app
  - $ `sudo mysql -p`
  - Enter the password you just set.
  - mysql> `CREATE DATABASE dashboard`
  - ->`DEFAULT CHARACTER SET utf8`
  - ->`DEFAULT COLLATE utf8_general_ci;`
  - mysql> `exit;`

- Assign ownership to yourself for the web directory /var/www
  - $ `sudo chown <username> /var/www`

- Install RVM (Ruby Version Manager) and configure the Dashboard's current Ruby version, as the deploying user
  - $ `gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB`
  - $ `\curl -sSL https://get.rvm.io | bash -s stable`
  - $ `source /home/ragesoss/.rvm/scripts/rvm`
  - logout and back in again so that these settings take effect
  - $ `rvm install 3.1.2`
    - This will probably report that ruby is already installed, but we do this just in case.
  - $ `rvm --default use 3.1.2`

- Install Phusion Passenger module for Apache
  - $ `gem install passenger`
  - $ `rvmsudo passenger-install-apache2-module`
    - look out for errors or missing dependencies and follow all directions which likely include adding some code to the apache configuration, as follows...
  - $ `sudo nano /etc/apache2/apache2.conf`
  - Add to the end the text instructed by the passenger installer, something like:

```
LoadModule passenger_module /home/ragesoss/.rvm/gems/ruby-2.7.1/gems/passenger-6.0.8/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /home/ragesoss/.rvm/gems/ruby-2.7.1/gems/passenger-6.0.8
  PassengerDefaultRuby /home/ragesoss/.rvm/gems/ruby-2.7.1/wrappers/ruby
</IfModule>
```

  - within that Passenger block, add an additional rule to configure the PIDs directory:
```
  PassengerInstanceRegistryDir /var/www/dashboard/shared/tmp/pids
```
  - At the end of the apache.conf, add the following:
```
# Add header to incoming requests, timestamping them with time since the epoch in microseconds
# This is required for New Relic's request queueing calculation
RequestHeader set X-Request-Start "%t"
```

- Enable mod_headers:
  - $ `sudo a2enmod headers`

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

ON GITHUB
-------------

- Fork this github repo.


ON YOUR MACHINE
-------------

- Clone your forked github repo
- Get the Dashboard running locally (by installing all the necessary stuff)
- Update or create the corresponding deployment file (eg, '/config/deploy/programs-and-events.rb') to point to your new wmflabs instance, commit the changes and push to github
- Start the Capistrano deployment (on production). Enter the app's directory, then:
  - $ `cap production deploy`
  - This is expected to fail because configuration files are not yet in place — in particular, application.yml, database.yml, secrets.yml, and newrelic.yml
   - If it fails but you don't get a message about one of those files, try it again.


ON THE SERVER
-------------

- Create application.yml, database.yml, and secrets.yml in /var/www/dashboard/shared/config
   - (Use application.example.yml and database.example.yml as the basis for those respectivie files. Use a username and password for a new account you create just for the dashboard. Update the database password to the one you chose when creating the database.)
  - $ `nano /var/www/dashboard/shared/config/application.yml`
  - Paste and edit the example file, then save.
  - $ `nano /var/www/dashboard/shared/config/database.yml`
  - Paste and edit the example file, then save.
  - $ `nano /var/www/dashboard/shared/config/secrets.yml`
  - Paste the standard file, then save.
  - $ `touch /var/www/dashboard/shared/config/newrelic.yml`
  - (No file content is necessary unless you're using New Relic monitoring.)
- Create the tmp directory for pid files
  - $ `mkdir /var/www/dashboard/shared/tmp/pids`
  - (Sidekiq will create a pid file in this directory upon deployment. If it is unable to do so, background jobs will not be performed.)

- Add systemd services for the app's sidekiq processes
  - copy the .service files from `server_config/systemd` into the systemd directory ( `/etc/systemd/system` on Debian)
    - Change the user and group lines to match the user who owns the deployment process (and one of their groups)
  - enable each service: `systemctl enable sidekiq-default`, etc.

ON YOUR MACHINE
-------------

- Run the capistrano deployment again from the app's directory:
  - $ `cap production deploy`


ON THE SERVER
-------------

- For a fresh site, add a SECRET_KEY_BASE to the environment:
  - $ `cd /var/www/dashboard/current`
  - $ `rake secret`
  - Copy the secret key output and paste it into the secrets.yml file
    - $ `nano /var/www/dashboard/shared/config/secrets.yml`
    - Paste the key in as the value of "secret_key_base:"

- For an existing site, copy over the secret.yml file from the extant server to preserve login cookies

- Enable the site
  - $ `sudo a2dissite 000-default`
  - $ `sudo a2ensite dashboard`
  - $ `sudo service apache2 restart`


ON YOUR MACHINE
-------------

- Run the capistrano deployment one last time from the app's directory:
  - $ `cap production deploy`
- Visit your new dashboard!

ON THE SERVER
-------------

- To allow multiple users to deploy, change the permissions for everything in the dashboard directory to allow group write access:
  - $ `cd /var/www`
  - $ `sudo chmod g+w -R dashboard`

## Copying from one production server to another

COPYING USER PROFILES
-------------

- Copy user profile photos from the old server to your new server.
  - $ `scp -r3 <old>:/var/www/dashboard/current/public/system/user_profiles <new>:/var/www/dashboard/current/public/system`
- Fix the permissions on the new server:
  - $ `sudo chown -R <new_server_user> /var/www/dashboard/current/public/system`

UPLOADING DATABASE
-------------

- Download the most recent database backup and/or version
  - $ `mysqldump --user=wiki --password=$DB_PASSWORD --host=<hostname> dashboard > /path/to/your/backup.sql`
- Upload the database to the new server
  - $ `mysql -u wiki -p dashboard < <your-file>.sql`

CONFIGURING RAILS CONSOLE
-------------

- From `/var/www/dashboard/current` run `bundle exec rake app:update:bin`
- If `bundle exec rails c -e production` does not work, you may need to edit the paths in `bin/rails` to work with the Capistrano directory structure: replace `../config` with `../../current/config`.

CONFIGURING A SEPARATE SIDEKIQ NODE
-------------

- Configure the node running Redis to allow connections from other servers by editing `/etc/redis/redis.conf`
  - Comment out the `bind` setting to allow connections from all interfaces
  - Find the `protected-mode yes` line and change it to `protected-mode no`
  - `sudo service redis restart`

- Spin up a fresh server and log in to it
- Install requirements:
  - `sudo apt install pandoc libmariadb-dev imagemagick gnupg2 shared-mime-info`
- Install RVM (see above)
- Get the Dashboard code: `git clone https://github.com/WikiEducationFoundation/WikiEduDashboard.git`
- In the Dashboard directory:
  - `bundle install`
  - Copy `application.yml`, `database.yml`, `secrets.yml`, `newrelic.yml` from the web node into the `config` directory

- Add the systemd service files for the sidekiq processes you want to run on this server.
  - Add the Redis URL to the `[Service]` block, something like: `Environment=REDIS_URL=redis://p-and-e-dashboard-web`
  - Update the `WorkingDirectory` to something like `/home/ragesoss/WikiEduDashboard`

- Enable and start the service

To update for new deployments, you'll need to quiet these sidekiq processes, stop them, do a `git pull` and `bundle install`, then restart the sidekiq processes.
