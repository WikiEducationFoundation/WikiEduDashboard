set :branch, 'wikiedu-dashboard-staging'
set :rails_env, 'staging'

role :app, %w(ragesoss@wikiedu-dashboard-staging.globaleducation.eqiad.wmflabs)
role :web, %w(ragesoss@wikiedu-dashboard-staging.globaleducation.eqiad.wmflabs)
role :db,  %w(ragesoss@wikiedu-dashboard-staging.globaleducation.eqiad.wmflabs)

set :user, 'ragesoss'
set :address, 'wikiedu-dashboard-staging.globaleducation.eqiad.wmflabs'

set :deploy_to, '/var/www/dashboard'
