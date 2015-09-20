require 'browser'

Rails.configuration.middleware.use Browser::Middleware do
  supported = !browser.ie? || browser.version.to_i >= 10
  redirect_to '/unsupported_browser' unless supported
end
