# frozen_string_literal: true

# Chrome 158 rejects the '*' origin that Capybara 3.40.0 passes to
# Storage.clearDataForOrigin in reset!, failing every JS spec on teardown.
# We only clear cookies there (clear_local_storage: false), so clear them directly.
# Remove once Capybara ships a fix: https://github.com/teamcapybara/capybara/issues/2865
module ChromeWildcardOriginResetFix
  private

  def execute_cdp(cmd, params = {})
    if cmd == 'Storage.clearDataForOrigin' && params[:origin] == '*'
      return super('Network.clearBrowserCookies')
    end
    super
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeWildcardOriginResetFix)
