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

## RVM, Passenger, Apache

- Install RVM (Ruby Version Manager) and configure the Dashboard's current Ruby version, as the deploying user
  - $ `gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB`
  - $ `\curl -sSL https://get.rvm.io | bash -s stable`
  - $ `source /home/ragesoss/.rvm/scripts/rvm`
  - logout and back in again so that these settings take effect
  - $ `rvm install 3.1.2`
  - $ `rvm --default use 3.1.2`

- Install Phusion Passenger module for Apache
  - $ `gem install passenger`
  - $ `rvmsudo passenger-install-apache2-module`
    - look out for errors or missing dependencies and follow all directions which likely include adding some code to the apache configuration, as follows...
  - $ `sudo nano /etc/apache2/apache2.conf`
  - Add to the end the text instructed by the passenger installer, something like:

```
   LoadModule passenger_module /home/ragesoss/.rvm/gems/ruby-3.1.2/gems/passenger-6.0.22/buildout/apache2/mod_passenger.so
   <IfModule mod_passenger.c>
     PassengerRoot /home/ragesoss/.rvm/gems/ruby-3.1.2/gems/passenger-6.0.22
     PassengerDefaultRuby /home/ragesoss/.rvm/gems/ruby-3.1.2/wrappers/ruby
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

## Deployment

- Update or create the corresponding deployment file (eg, '/config/deploy/peony.rb') to point to your new wmcloud instance (and commit the changes and push to github, once it works),
- Start the Capistrano deployment. Enter the app's directory, then:
  - $ `bundle exec cap peony deploy`
  - This is expected to fail because configuration files are not yet in place — in particular, application.yml, database.yml, secrets.yml, and newrelic.yml
   - If it fails but you don't get a message about one of those files, try it again.
- Copy the `config` and `public` directory contents on to the new server at the same location (`/var/www/dashboard/shared/`)
- Create the tmp directory for pid files
  - $ `mkdir /var/www/dashboard/shared/tmp/pids`
  - (Sidekiq will create a pid file in this directory upon deployment. If it is unable to do so, background jobs will not be performed.)

- Add systemd services for the app's sidekiq processes. The `default` and `constant` and `daily` should be safe to run on the same server as the web app. Others should be on separate servers.
  - copy the .service files from `server_config/systemd` into the systemd directory ( `/etc/systemd/system` on Debian)
    - Change the user and group lines to match the user who owns the deployment process (and one of their groups)
  - enable each service: `systemctl enable sidekiq-default`, etc.

- Enable the site
  - $ `sudo a2dissite 000-default`
  - $ `sudo a2ensite dashboard`
  - $ `sudo systemctl reload apache2`
  - $ `sudo service apache2 restart`

