hot_loading = ENV['hot_loading'] == 'true'
host = hot_loading && Rails.env.development? ? "localhost:8080" : "localhost:3000"
if Rails.env.development?
  require_dependency Rails.root.join('lib/development/dev_server_proxy')
  Rails.application.config.middleware.use WebpackDevServerProxy, dev_server_host: host
end

