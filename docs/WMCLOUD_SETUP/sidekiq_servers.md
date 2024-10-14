These are notes from setting up a fresh set of servers for Sidekiq workers, July 2, 2024.

My strategy this time is to put every worker on a separate VM, so try to make the bottlenecks and failures for too-large updates more isolated.

* Create servers (8-core for long, 8-core for medium, 4-core for short queue).

## Each server

- Spin up a fresh server and log in to it
- Install requirements:
  - `sudo apt install pandoc libmariadb-dev imagemagick gnupg2 shared-mime-info`
- Install RVM (see web server doc)
- Get the Dashboard code: `git clone https://github.com/WikiEducationFoundation/WikiEduDashboard.git`
- In the Dashboard directory:
  - `bundle install`
  - Copy `application.yml`, `database.yml`, `secrets.yml`, `newrelic.yml` from the web node into the `config` directory

- Add the systemd service files for the sidekiq processes you want to run on this server. (These are typically in `/etc/systemd/system/[name].service`.)
  - Make sure the path is correct for RVM in `ExecStart`
  - Update the `WorkingDirectory` to something like `/home/ragesoss/WikiEduDashboard`

- Enable and start the service, eg:
  - `sudo systemctl enable sidekiq-medium.service`
  - `sudo systemctl start sidekiq-medium.service`

To update for new deployments, you'll need to quiet these sidekiq processes, stop them, do a `git pull` and `bundle install`, then restart the sidekiq processes.
