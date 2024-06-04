set :branch, 'data-rearchitecture-for-dashboard'
set :rails_env, 'production'

role :app, %w(gabina@data-rearchitecture-project-test.globaleducation.eqiad1.wikimedia.cloud)
role :web, %w(gabina@data-rearchitecture-project-test.globaleducation.eqiad1.wikimedia.cloud)
role :db,  %w(gabina@data-rearchitecture-project-test.globaleducation.eqiad1.wikimedia.cloud)

set :user, 'gabina'
set :address, 'data-rearchitecture-project-test.globaleducation.eqiad1.wikimedia.cloud'

set :deploy_to, '/var/www/dashboard'
