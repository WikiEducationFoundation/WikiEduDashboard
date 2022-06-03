## Capistrano deployments

* `rails c -e production` from the `/current` deployment directory doesn't work.
  * Install binstubs: `bundle install --binstubs`.

* Capistrano cannot restart sidekiq processes because the deploying user lacks passwordless sudo.
  * Configure that user for passwordless sudo:
    * Edit `/etc/sudoers`
    * add `deploying_user ALL=(ALL) NOPASSWD: ALL` at the end
