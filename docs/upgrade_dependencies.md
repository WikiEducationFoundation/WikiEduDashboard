## Upgrading Ruby ##

Update the code where the specific Ruby version is specified:
* `Gemfile`
* `.travis.yml`

On the server where the dashboard is already running, in `/var/www/dashboard/current`:
* `rvm install ruby-x.x.x`
* `rvm --default use x.x.x`
* `gem install bundler`
* `gem install passenger`
* `cd ~`
* `rvmsudo passenger-install-apache2-module`

Passenger should now be ready. Change the Apache configuration to use it as soon a version of the dashboard gets deployed with the new Ruby version.
* `sudo nano /etc/apache2/apache2.conf`
* Change the ruby version in the passenger configuration, per the output of the passenger installation command.
* `sudo service apache2 restart`
