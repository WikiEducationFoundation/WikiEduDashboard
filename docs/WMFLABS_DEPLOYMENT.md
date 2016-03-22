ON WIKITECH
-------------

- On wikitech, join or create a project. Create a web security group, with ports 80 and 443 open.

- Create an instance on wikitech:
  - ubuntu or debian should work fine
  - Security groups: default, web

- Create a web proxy for this new instance. This will determine the url of your dashboard (something like educationdashboard.wmflabs.org)

ON THE SERVER
-------------

- ssh into this new instance from your machine

- install some additional packages needed by the app and web server
  - $ `sudo apt-get install libmysqlclient-dev build-essential apache2 apache2-threaded-dev libapr1-dev libaprutil1-dev mysql-server libssl-dev libyaml-dev libreadline-dev openssl curl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev sqlite3 pandoc nodejs`
  - Set the mysql server password and record this password. (You'll need it shortly.)

- Create a database for the app
  - $ `sudo mysql -p`
  - Enter the password you just set.
  - mysql> `CREATE DATABASE dashboard`
  - ->`DEFAULT CHARACTER SET utf8`
  - ->`DEFAULT COLLATE utf8_general_ci;`
  - mysql> `exit;`

- Assign ownership to yourself for the web directory /var/www
  - $ `sudo chown <username> /var/www`

- Install RVM (Ruby Version Manager) and configure Ruby 2.1.5
  - $ `gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3`
  - $ `curl -sSL https://get.rvm.io | sudo bash -s stable`
  - $ `sudo usermod -a -G rvm <username>`
  - logout and back in again so that these settings take effect
  - $ `rvm install 2.1.5`
    - This will probably report that ruby-2.1.5 is already installed, but we do this just in case.
  - $ `rvm --default use 2.1.5`

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

- Create a VirtualHost for the app
  - $ `sudo nano /etc/apache2/sites-available/dashboard.conf`
  - Add something like this:

```
<VirtualHost *:80>
  ServerAdmin sage@ragesoss.com
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
   - If it fails but you do't get a message about one of those files, try it again.


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
  - $ `sudo a2ensite dashboard`
  - $ `sudo service apache2 restart`


ON YOUR MACHINE
-------------

- Run the capistrano deployment one last time from the app's directory:
  - $ `cap production deploy`
- Create the cohorts:
  - $ `cap production sake task=cohort:add_cohorts`
- Visit your new dashboard!
