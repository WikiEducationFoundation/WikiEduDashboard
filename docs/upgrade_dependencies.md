## Upgrading Ruby ##

### Prepare the code
Update the code where the specific Ruby version is specified:
* `Gemfile`
* `.github/workflows/ci.yml`
* `docs/setup.md` and related setup scripts
* `Dockerfile`

Make sure the tests pass on travis with the new Ruby.

### Prepare for deployment

* Quiet all Sidekiq processes and wait for them to complete their jobs.

### Prepare Ruby and Passenger on the server

On the server where the dashboard is already running, in `/var/www/dashboard/current`:
* `rvm get head` (to ensure the new ruby is available)
* `rvm install ruby-x.x.x`
* `gem install bundler`
* `gem install passenger`
* `cd ~`
* `rvm --default use x.x.x`
* `rvmsudo passenger-install-apache2-module`

Passenger should now be ready. Copy the output for updating the apache config.
It will be something like this:
```
LoadModule passenger_module /home/sage/.rvm/gems/ruby-3.1.2/gems/passenger-6.0.14/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /home/sage/.rvm/gems/ruby-3.1.2/gems/passenger-6.0.14
  PassengerDefaultRuby /home/sage/.rvm/gems/ruby-3.1.2/wrappers/ruby
</IfModule>

```

### Deploy

Change the Apache configuration to use it as soon a version of the dashboard gets deployed.
* `sudo nano /etc/apache2/apache2.conf`
* Change the PassengerDefaultRuby path, the PassengerRoot path, and the passenger_module path in the apache configuration, per the output of the passenger installation command. (Leave PassengerDefaultUser and PassengerInstanceRegisteryDir as they are.)

Now deploy as usual with the upgraded Ruby version. This will break the app until you restart apache:

* `sudo service apache2 restart`


### Post-deployment

* Sidekiq processes should have restarted during deployment.

### Troubleshooting

If passenger is failing to restart:
* Make sure rvm is available and defaults to the new version for the deploy user. This may differ between a login (ssh) session and a non-login Capistrano session. Check `/etc/bash.bashrc` and `~/.bashrc`, and make sure rvm is being sourced properly.
* Make sure Capistrano is trying to use the correct version of passenger. Add debugging commands, like `passenger -v`, to `config/deploy/production.rb`.
* Make sure Capistrano is using the new ruby version and the corresponding passenger executables.
