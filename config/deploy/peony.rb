set :branch, 'wmflabs'
set :rails_env, 'production'

role :app, %w(peony-web.globaleducation.eqiad1.wikimedia.cloud)
role :web, %w(peony-web.globaleducation.eqiad1.wikimedia.cloud)
role :db, %w(peony-web.globaleducation.eqiad1.wikimedia.cloud)

set :address, 'peony-web.globaleducation.eqiad1.wikimedia.cloud'

set :user, File.read('.deploy_user').strip
set :deploy_to, '/var/www/dashboard'
set :default_env, { 'PASSENGER_INSTANCE_REGISTRY_DIR' => '/var/www/dashboard/shared/tmp/pids' }