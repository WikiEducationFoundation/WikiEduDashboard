## Upgrading Ruby ##

### Install the new Ruby in your development environment

If using RVM:
* `rvm get head`
* `rvm install ruby-x.x.x`
* `gem install bundler`
* `bundle install` from the project directory

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

On non-web application servers (ie, servers just running Sidekiq processes):
* stop the Sidekiq processes
* install Ruby and Bundler, and set the default
* pull the latest code and run `bundle install` (with the new Ruby version)
* restart the Sidekiq processes

### Note:

When running under Passenger, Ruby may activate its default gems
before Bundler is loaded. This differs from local development, where
the app is usually started with `bundle exec` and Bundler controls
gem activation from the beginning.

If a default Ruby gem (for example `base64`) is explicitly listed
in the Gemfile with a different version, Bundler cannot replace the
already-activated version. In production this causes the application
to fail during boot with a `Gem::LoadError`, and Passenger reports a
"spawning error".

This issue may not appear in local development or CI, but only when
deploying under Passenger.

#### Mitigation

To avoid this issue when deploying with Passenger:

- Avoid explicitly pinning default Ruby gems in the Gemfile unless required
- Ensure Bundler is loaded before application boot by enabling:

```apache
PassengerPreloadBundler on
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
