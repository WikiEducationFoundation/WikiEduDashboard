# frozen_string_literal: true

# When SCREENSHOT=before or SCREENSHOT=after is set, save a screenshot at the
# end of every feature spec example, into tmp/screenshots/{before,after}/.
#
# Usage (normally invoked by bin/pr-screenshots, not directly):
#   SCREENSHOT=after bundle exec rspec spec/features/foo_spec.rb
#
module ScreenshotMode
  def self.capture(example, page)
    label = ENV.fetch('SCREENSHOT', nil)
    return unless label
    dir = Rails.root.join("tmp/screenshots/#{label}")
    FileUtils.mkdir_p(dir)
    file_name = example.file_path.split('/').last.delete_suffix('.rb')
    description = example.description.tr(' ', '-').gsub(/["*:<>|?\\\r\n\/]/, '').slice(0, 60)
    path = dir.join("#{file_name}__#{description}.png").to_s
    begin
      page.save_screenshot(path)
    rescue StandardError
      nil # page may not be open (e.g. an example that never visited a page)
    end
  end
end

if ENV['SCREENSHOT']
  RSpec.configure do |config|
    # JS feature specs are captured from the browser-cleanup hook in
    # rails_helper.rb instead: that hook navigates to about:blank and runs
    # before any hook registered here could take a screenshot, so it has to
    # do the capturing itself. This hook covers non-JS feature specs only.
    config.after(:each, type: :feature) do |example|
      ScreenshotMode.capture(example, page) unless example.metadata[:js]
    end
  end
end
