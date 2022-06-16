# frozen_string_literal: true
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
