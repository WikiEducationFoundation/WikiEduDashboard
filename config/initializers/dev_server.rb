require_dependency "#{Rails.root}/lib/dev_server_proxy"
host = Features.hot_loading? && Rails.env.development? ? "localhost:8080" : "localhost:3000"
if not Rails.env.production?
  Rails.application.config.middleware.use WebpackDevServerProxy, dev_server_host: host
end

