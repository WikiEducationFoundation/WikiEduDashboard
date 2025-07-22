# frozen_string_literal: true
# This proxy forwards requests to /assets/*.* to the Webpack Dev Server(localhost:8080 by default)
# It is used when running `yarn hot`
# You can find a similar example here https://github.com/ncr/rack-proxy#rails-middleware-example
# This proxy is added as a middleware in config/initializers/dev_server.rb and only gets called
# during testing/development.

class WebpackDevServerProxy < Rack::Proxy
  def initialize(app = nil, opts = {})
    super
    @dev_server_host = opts[:dev_server_host]
  end

  def perform_request(env)
    if env['PATH_INFO'].start_with?('/assets/') # Specify asset paths to proxy
      env['HTTP_HOST'] = @dev_server_host
      super
    else
      @app.call(env)
    end
  end
end
