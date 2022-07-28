hot_loading = ENV['hot_loading'] == 'true'
host = hot_loading && Rails.env.development? ? "localhost:8080" : "localhost:3000"
if not Rails.env.production?
  require_dependency "#{Rails.root}/lib/development/dev_server_proxy"
  Rails.application.config.middleware.use WebpackDevServerProxy, dev_server_host: host
end

