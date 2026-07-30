# frozen_string_literal: true

require 'tempfile'
require 'open3'
require 'shellwords'

# Runs a Ruby script in the staging dashboard's Rails environment via
# SSH. Uses the same pattern that Phase H of the smoke-test ran by hand:
# scp the script to /tmp on staging, then
# `bundle exec ruby -r./config/environment.rb <script>` in a login shell
# (so RVM's rails 8.x is on PATH).
#
# State-shaping that's awkward or impossible via the dashboard's HTTP
# surface — approving a course, creating a binding directly, querying
# AR state for assertions — goes through this. Course CRUD that the
# dashboard exposes as a controller endpoint can also go through here,
# bypassing HTTP auth (we use root SSH instead of a session cookie).
#
# Authentication: relies on the developer's SSH key being authorized to
# log in as STAGING_DASHBOARD_SSH_USER on STAGING_DASHBOARD_SSH_HOST,
# the same key they use for `cap staging deploy`.
module DashboardConsole
  RELEASE_PATH = '/var/www/dashboard/current'
  RAILS_ENV = 'staging'

  class ExecutionError < StandardError; end

  def self.host
    ENV.fetch('STAGING_DASHBOARD_SSH_HOST', 'dashboard-testing.wikiedu.org')
  end

  def self.user
    ENV.fetch('STAGING_DASHBOARD_SSH_USER', 'root')
  end

  # Run a Ruby script string on staging in the Rails environment.
  # Returns the script's stdout as a string. Raises ExecutionError on
  # non-zero exit. The script can read constants / models / services
  # exactly as if it were running in a Rails console.
  def self.run(script)
    upload_path = "/tmp/staging-spec-#{Time.now.to_i}-#{rand(10_000)}.rb"
    Tempfile.create(['staging-spec', '.rb']) do |local|
      local.write(script)
      local.close
      scp(local.path, upload_path)
    end

    stdout, stderr, status = exec_remote(remote_command(upload_path))
    raise ExecutionError, "ssh failed: #{stderr.strip}" unless status.success?

    stdout
  ensure
    exec_remote("rm -f #{Shellwords.escape(upload_path)}") if upload_path
  end

  # Convenience: run a script that ends with `puts result.to_json`, parse
  # back into a Ruby value. Callers can `DashboardConsole.run_json("...")`
  # without re-deriving the parse pattern.
  def self.run_json(script)
    require 'json'
    JSON.parse(run(script))
  end

  def self.scp(local_path, remote_path)
    target = "#{user}@#{host}:#{remote_path}"
    _, stderr, status = Open3.capture3('scp', '-q', '-o', 'BatchMode=yes', local_path, target)
    return if status.success?

    raise ExecutionError, "scp to #{target} failed: #{stderr.strip}"
  end

  def self.exec_remote(command)
    Open3.capture3('ssh', '-o', 'BatchMode=yes', "#{user}@#{host}", command)
  end

  def self.remote_command(script_path)
    [
      "bash -lc 'cd #{Shellwords.escape(RELEASE_PATH)} && ",
      "RAILS_ENV=#{RAILS_ENV} bundle exec ruby -r./config/environment.rb ",
      "#{Shellwords.escape(script_path)}'"
    ].join
  end
end
