# config valid only for current version of Capistrano
lock '3.10.1'

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
                                                 'config/newrelic.yml')

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

  desc 'Run gulp to compile the assets'
  task :local_gulp_build do
    run_locally do
      execute 'gulp build'
    end
  end

  desc 'Upload compiled assets'
  task :upload_compiled_assets do
    run_locally do
      execute "rsync -r -u -v public/assets/ #{fetch(:user)}@#{fetch(:address)}:#{release_path}/public/assets"
    end
  end

  desc 'ensure permissions on /tmp'
  task :ensure_tmp_permissions do
    on roles(:all) do
      # Ignore chmod errors and force an exit code of 0, so that Capistrano
      # continues deployment. This reduces the breakage when there are
      # permissions problems with the tmp directory.
      execute "chmod -R 777 #{current_path}/tmp/cache || :"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # nothing
    end
  end

  before 'deploy:rollback', 'deploy:do_not_update_assets'
  before :deploy, 'deploy:local_gulp_build' unless ENV['skip_gulp'] || skip_assets
  before 'deploy:restart', 'deploy:upload_compiled_assets' unless skip_assets
  before 'deploy:restart', 'deploy:ensure_tmp_permissions'

end
