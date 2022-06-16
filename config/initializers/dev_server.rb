require_dependency "#{Rails.root}/lib/dev_server_proxy"
if Features.hot_loading? && Rails.env.development?
  Rails.application.config.middleware.use WebpackDevServerProxy, dev_server_host: "localhost:8080"
end