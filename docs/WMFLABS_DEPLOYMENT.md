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

- install some additional packages needed by the app and web server
  - $ `sudo apt-get install pandoc redis-server mariadb-server libmariadb-dev imagemagick gnupg2 apache2 apache2-dev apache2-mpm-worker libcurl4-openssl-dev libapr1-dev libaprutil1-dev`

- configure mariaDB to use /srv as the location of database files:
  - `sudo systemctl stop mysql`
  - `mv /var/lib/msyql /srv/mysql`
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

- Create a database for the app
  - $ `sudo mysql -p`
  - Enter the password you just set.
  - mysql> `CREATE DATABASE dashboard`
  - ->`DEFAULT CHARACTER SET utf8`
  - ->`DEFAULT COLLATE utf8_general_ci;`
  - mysql> `exit;`

- Assign ownership to yourself for the web directory /var/www
  - $ `sudo chown <username> /var/www`

- Install RVM (Ruby Version Manager) and configure Ruby 2.1.5, as the `deploy` user
  - $ `gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB`
  - $ `\curl -sSL https://get.rvm.io | bash -s stable`
  - $ `source /home/deploy/.rvm/scripts/rvm`
  - $ `sudo usermod -a -G rvm <username>`
  - logout and back in again so that these settings take effect
  - $ `rvm install 2.7.1`
    - This will probably report that ruby is already installed, but we do this just in case.
  - $ `rvm --default use 2.7.``

- Install Phusion Passenger module for Apache
  - $ `gem install passenger`
  - $ `rvmsudo passenger-install-apache2-module`
    - look out for errors or missing dependencies and follow all directions which likely include adding some code to the apache configuration, as follows...
  - $ `sudo nano /etc/apache2/apache2.conf`
  - Add to the end the text instructed by the passenger installer, something like:

```
LoadModule passenger_module /home/ragesoss/.rvm/gems/ruby-2.1.5/gems/passenger-4.0.58/buildout/apache2/mod_passenger.so
   <IfModule mod_passenger.c>
     PassengerRoot /home/ragesoss/.rvm/gems/ruby-2.1.5/gems/passenger-4.0.58
     PassengerDefaultRuby /home/ragesoss/.rvm/gems/ruby-2.1.5/wrappers/ruby
   </IfModule>
```

  - within that passenter block, add an additional rule to configure the PIDs directory:
```
  PassengerInstanceRegistryDir /var/www/dashboard/shared/tmp/pids
```

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


ON GITHUB
-------------

- Fork this github repo.


ON YOUR MACHINE
-------------

- Clone your forked github repo
- Get the Dashboard running locally (by installing all the necessary stuff)
- Update '/config/deploy/production.rb' (and '/config/deploy/staging.rb') to point to your new wmflabs instance, commit the changes and push to github
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
  - Add a `skylight.yml` file with Skylight keys
- Create the tmp directory for pid files
  - $ `mkdir /var/www/dashboard/shared/tmp/pids`
  - (Sidekiq will create a pid file in this directory upon deployment. If it is unable to do so, background jobs will not be performed.)

- Add systemd services for the app's sidekiq processes
  - copy the .service files from `server_config/systemd` into the systemd directory ( `/etc/systemd/system` on Debian)
    - Change the user and group lines to match the user who owns the deployment process (and one of their groups)
  - enable each service: `systemcl enable sidekiq-default`, etc.

ON YOUR MACHINE
-------------

- Run the capistrano deployment again from the app's directory:
  - $ `cap production deploy`


ON THE SERVER
-------------

- Add a SECRET_KEY_BASE to the environment:
  - $ `cd /var/www/dashboard/current`
  - $ `rake secret`
  - Copy the secret key output and paste it into the secrets.yml file
    - $ `nano /var/www/dashboard/shared/config/secrets.yml`
    - Paste the key in as the value of "secret_key_base:"

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

- Copy user profiles from the old server to your new server.
  - $ `scp -r3 <old>:/var/www/dashboard/current/public/system/user_profiles <new>:/var/www/dashboard/current/public/system`

UPLOADING DATABASE
-------------

- Download the most recent database backup and/or version
  - $ `mysqldump --user=wiki --password=$DB_PASSWORD --host=<hostname> dashboard > /path/to/your/backup.sql`
- Upload the database to the new server
  - $ `mysql -u wiki -p dashboard < <your-file>.sql`
