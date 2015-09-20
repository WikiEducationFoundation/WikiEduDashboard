require 'browser'
Browser.modern_rules << -> b { b.ie? && b.version.to_i >= 10 }

Rails.configuration.middleware.use Browser::Middleware do
  redirect_to '/unsupported_browser' unless browser.modern?
end
