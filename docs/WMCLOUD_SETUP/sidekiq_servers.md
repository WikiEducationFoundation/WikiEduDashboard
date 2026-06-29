These are notes from setting up a fresh set of servers for Sidekiq workers, July 2, 2024.

My strategy this time is to put every worker on a separate VM, so try to make the bottlenecks and failures for too-large updates more isolated.

* Create servers (8-core for long, 8-core for medium, 4-core for short queue).

## Each server

- Spin up a fresh server and log in to it
- Install requirements:
  - `sudo apt install pandoc libmariadb-dev imagemagick gnupg2 shared-mime-info`
- Install RVM [(see web server doc)](./web_server.md)
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

## Scaling a queue across cores: multiple processes, not high concurrency

The single-process-per-queue layout above keeps `--concurrency 1`. When a queue
(especially `long_update`) gets backlogged on a multi-core box, the instinct is
to raise `--concurrency`, but that does **not** add CPU throughput: MRI Ruby
holds one GVL per process, so a single `--concurrency 3` process executes Ruby on
only ~1 core no matter how many cores the VM has. Separately — and at any
concurrency, including `--concurrency 1` — a worker thread grinding through
CPU-bound Ruby (e.g. timeslice reprocessing) starves the Sidekiq heartbeat
thread, which shows up as a misleading warning roughly once a minute even though
Redis and the network are fine:

```
WARN ... Your Redis network connection appears to be performing poorly.
```

The RTT it reports is really the time the heartbeat thread waited to re-acquire
the GVL after its Redis `PING`, not a network round trip. The tell: if `uptime`
shows the box mostly idle and `free -h` shows no swap while this warning fires,
it's GVL contention inside the process, not Redis.

This warning is benign (the process heartbeat TTL is 60s, far longer than the
~200ms stalls it reports) and is **not** a reliable signal that concurrency is
too high. Splitting into multiple single-threaded processes is about throughput,
not about silencing it — expect each busy long worker to keep logging it. If the
log noise is a problem, filter it downstream rather than chasing a nonexistent
Redis issue.

To actually use the cores, run several independent single-threaded processes on
the same queue. Each process has its own GVL and runs on its own core. Use the
templated unit `sidekiq-long@.service`:

```
sudo cp server_config/systemd/sidekiq-long@.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl disable --now sidekiq-long          # retire the single conc-3 unit
sudo systemctl enable --now sidekiq-long@1 sidekiq-long@2 sidekiq-long@3
```

Each `@N` is a separate process; the parallelism is the same as one
`--concurrency N` process, just spread across real cores, so it adds no
job-level concurrency risk beyond what that single process already had. Add or
remove instances (`sidekiq-long@4`, ...) to match the backlog, watching:

- **Memory**: each instance is a full Rails heap (~0.5–1 GiB with
  `MALLOC_ARENA_MAX=2`). Keep the `available` figure in `free -h` above ~2 GiB.
- **Cores**: keep the load average a couple below the core count so the
  `constant` process and the OS aren't starved.

If load and memory both stay low but the queue still drags, the jobs are
I/O-bound (waiting on the replica DB), and one thread per process leaves its core
idle during those waits — bump each instance to `--concurrency 2` to overlap I/O.
The same template pattern applies to any other CPU-heavy queue.

*(This section was written by Claude Code.)*
