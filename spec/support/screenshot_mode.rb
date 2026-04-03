# frozen_string_literal: true

# When SCREENSHOT=before or SCREENSHOT=after is set, save a screenshot at the
# end of every feature spec example, into tmp/screenshots/{before,after}/.
#
# Usage (normally invoked by bin/pr-screenshots, not directly):
#   SCREENSHOT=after bundle exec rspec spec/features/foo_spec.rb
#
if ENV['SCREENSHOT']
  RSpec.configure do |config|
    config.after(:each, type: :feature) do |example|
      label = ENV['SCREENSHOT']
      dir = Rails.root.join("tmp/screenshots/#{label}")
      FileUtils.mkdir_p(dir)
      file_name = example.file_path.split('/').last.delete_suffix('.rb')
      description = example.description.tr(' ', '-').gsub(/["*:<>|?\\\r\n\/]/, '').slice(0, 60)
      path = dir.join("#{file_name}__#{description}.png").to_s
      begin
        page.save_screenshot(path)
      rescue StandardError
        nil # page may not be open (e.g. non-JS example that never visited)
      end
    end
  end
end
