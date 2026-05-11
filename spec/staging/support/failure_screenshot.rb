# frozen_string_literal: true

require 'fileutils'

# Save a screenshot + page source to `tmp/staging-failures/<spec>/` whenever
# a `:staging` example fails. Helps post-mortem real-browser failures where
# the spec error message alone doesn't tell you much.
RSpec.configure do |config|
  config.after(:each, :staging) do |example|
    next unless example.exception

    name = example.full_description.tr(' /', '__').gsub(/[^\w\-]/, '')
    dir = File.join(FAILURE_ARTIFACT_DIR, name)
    FileUtils.mkdir_p(dir)

    session = Capybara.current_session
    url = session.current_url.to_s
    if url.empty? || url == 'about:blank'
      warn "  [staging failure-artifact] no page loaded at failure; nothing to capture"
      next
    end

    png  = File.join(dir, 'screenshot.png')
    html = File.join(dir, 'page.html')
    session.save_screenshot(png)
    File.write(html, session.html)
    warn "  [staging failure-artifact] saved to #{dir} (at #{url})"
  rescue StandardError => e
    warn "  [staging failure-artifact] couldn't capture: #{e.message}"
  end
end
