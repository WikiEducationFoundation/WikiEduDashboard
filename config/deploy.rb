# config valid only for current version of Capistrano
lock '3.14.1'

set :application, 'wiki_edu_dashboard'
set :repo_url, 'git@github.com:WikiEducationFoundation/WikiEduDashboard.git'

set :ssh_options, forward_agent: true

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, false

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/application.yml',
                                                 'config/database.yml',
                                                 'config/secrets.yml',
                                                 'config/newrelic.yml',
                                                 'config/skylight.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
skip_assets = false

namespace :deploy do
  desc 'Disable building and upload of compiled assets'
  task :do_not_update_assets do
    skip_assets = true
  end

  desc 'Run yarn build to compile the assets'
  task :local_yarn_build do
    run_locally do
      execute 'yarn build'
    end
  end

  desc 'Upload compiled assets'
  task :upload_compiled_assets do
    run_locally do
      user = fetch(:user)
      user = user ? "#{user}@" : user
      execute "rsync -r -u -v public/assets/ #{user}#{fetch(:address)}:#{release_path}/public/assets"
    end
  end

  desc 'ensure permissions on /tmp'
  task :ensure_tmp_permissions do
    on roles(:all) do
      # Ignore chmod errors and force an exit code of 0, so that Capistrano
      # continues deployment. This reduces the breakage when there are
      # permissions problems with the tmp directory.
      execute "chmod -R 777 #{current_path}/tmp/cache || :"
      execute "chmod -R g+w #{release_path}"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # nothing
    end
  end

  before 'deploy:rollback', 'deploy:do_not_update_assets'
  before :deploy, 'deploy:local_yarn_build' unless ENV['skip_build'] || skip_assets
  before 'deploy:symlink:release', 'deploy:upload_compiled_assets' unless skip_assets
  before 'deploy:restart', 'deploy:ensure_tmp_permissions'

  ##############################
  # Sidekiq process management #
  ##############################

  # These sidekiq processes are managed by systemd. Each one has its own .service
  # file on the server; for reference, there are copies in server_config/systemd.
  # The typical location on debian is /etc/systemd/system.

  # These processes will all be started on system boot, and will restart if they fail
  # (but not if they are shut down cleanly). The strategy for deployment is to first
  # quiet all the processes so they don't accept new jobs, then stop them — killing incomplete
  # jobs and putting them back into the queue — then starting them again with the newly-deployed
  # code.

  # We interact with these processes using standard Unix signals, via `systemctl`
  # https://github.com/mperham/sidekiq/wiki/Signals

  # To leave sidekiq processes running through a deploy instead of restarting them:
  # `cap production deploy skip_sidekiq=true`
  set :sidekiq_processes, -> do
    [
      'sidekiq-default', # transactional jobs like wiki edits and sending email
      'sidekiq-short', # data updates for short-running courses, hopefully with low queue latency
      'sidekiq-medium', # data updates for typical courses
      'sidekiq-long', # data updates for long-running courses, which may have long queue latency
      'sidekiq-daily', # once-daily long-running data update tasks
    ]
  end
  set :sidekiq_roles, -> { :app }

  namespace :sidekiq do
    desc 'Quiet sidekiq (stop fetching new tasks from Redis)'
    task :quiet do
      on roles fetch(:sidekiq_roles) do
        fetch(:sidekiq_processes).each do |service|
          execute :sudo, 'systemctl', 'kill', '-s', 'TSTP', service, raise_on_non_zero_exit: false
        end
      end
    end
  
    desc 'Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
    task :stop do
      on roles fetch(:sidekiq_roles) do
        fetch(:sidekiq_processes).each do |service|
          execute :sudo, 'systemctl', 'kill', '-s', 'TERM', service, raise_on_non_zero_exit: false
        end
      end
    end
  
    desc 'Start sidekiq'
    task :start do
      on roles fetch(:sidekiq_roles) do
        fetch(:sidekiq_processes).each do |service|
          execute :sudo, 'systemctl', 'start', service, raise_on_non_zero_exit: false
        end
      end
    end

    desc 'Restart sidekiq'
    task :restart do
      on roles fetch(:sidekiq_roles) do
        fetch(:sidekiq_processes).each do |service|
          execute :sudo, 'systemctl', 'restart', service, raise_on_non_zero_exit: false
        end
      end
    end
  end

  unless ENV['skip_sidekiq']
    after 'deploy:starting', 'sidekiq:quiet'
    before 'deploy:migrate', 'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
    after 'deploy:failed', 'sidekiq:restart'
  end
end
