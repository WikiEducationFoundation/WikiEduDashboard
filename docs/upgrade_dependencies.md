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
LoadModule passenger_module /home/sage/.rvm/gems/ruby-3.4.8/gems/passenger-6.1.2/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /home/sage/.rvm/gems/ruby-3.4.8/gems/passenger-6.1.2
  PassengerDefaultRuby /home/sage/.rvm/gems/ruby-3.4.8/wrappers/ruby
  PassengerPreloadBundler on
</IfModule>

```

On non-web application servers (ie, servers just running Sidekiq processes):
* stop the Sidekiq processes
* install Ruby and Bundler, and set the default
* pull the latest code and run `bundle install` (with the new Ruby version)
* restart the Sidekiq processes

### Deploy

Change the Apache configuration to use it as soon a version of the dashboard gets deployed.
* `sudo nano /etc/apache2/apache2.conf`
* Change the PassengerDefaultRuby path, the PassengerRoot path, and the passenger_module path in the apache configuration, per the output of the passenger installation command. (Leave PassengerDefaultUser and PassengerInstanceRegistryDir as they are.)

Now deploy as usual with the upgraded Ruby version. This will break the app until you restart apache:

* `sudo service apache2 restart`

### Post-deployment

* Sidekiq processes should have restarted during deployment.
* Update references throughout the documentation to replace the old Ruby version with the new one.
* Check each production server for course `flags` that no longer round-trip. Ruby ships Psych, whose YAML output can change between versions: Ruby 3.4 emits a nil value as `key:`, earlier versions as `key: `. Rails compares a serialized column against its stored bytes, so a course whose `flags` predate the change loads dirty and `Course#add_flag` raises instead of writing (PEONY-3CT). Detect it in a console on each server:

  ```ruby
  stale_ids = []
  Course.select(:id, :flags).find_each(batch_size: 500) do |course|
    course.flags # in-place comparison only starts once the attribute has been read
    stale_ids << course.id if course.will_save_change_to_flags?
  end
  puts stale_ids.count
  ```

  Only the bytes are stale; the values survive a dump/load cycle, so storing each row again under a row lock repairs it. Script in [PR #7080](https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/7080).

### Troubleshooting

If passenger is failing to restart:
* Make sure rvm is available and defaults to the new version for the deploy user. This may differ between a login (ssh) session and a non-login Capistrano session. Check `/etc/bash.bashrc` and `~/.bashrc`, and make sure rvm is being sourced properly.
* Make sure Capistrano is trying to use the correct version of passenger. Add debugging commands, like `passenger -v`, to `config/deploy/production.rb`.
* Make sure Capistrano is using the new ruby version and the corresponding passenger executables.
