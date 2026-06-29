set :branch, 'peony-staging'
set :rails_env, 'production'
set :ssh_options, paranoid: false

role :app, %w(peony-staging.globaleducation.eqiad1.wikimedia.cloud)
role :web, %w(peony-staging.globaleducation.eqiad1.wikimedia.cloud)
role :db,  %w(peony-staging.globaleducation.eqiad1.wikimedia.cloud)

set :user, 'ragesoss'
set :address, 'peony-staging.globaleducation.eqiad1.wikimedia.cloud'
set :repo_url, 'https://github.com/WikiEducationFoundation/WikiEduDashboard.git'

set :deploy_to, '/var/www/dashboard'
set :default_env, { 'PASSENGER_INSTANCE_REGISTRY_DIR' => '/var/www/dashboard/shared/tmp/pids' }
