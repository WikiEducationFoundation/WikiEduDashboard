# frozen_string_literal: true

module ApplicationHelper
  def hot_javascript_tag(filename)
    if ENV['feature'] == 'true' && filename == 'main'
      files = File.read('modules.txt').split("\n")
      paths = ''
      files.each do |file|
        paths += javascript_include_tag "/assets/javascripts/#{file}.js"
      end
      paths += javascript_include_tag hot_javascript_path('main')
      # rubocop:disable Rails/OutputSafety
      return paths.html_safe
      # rubocop:enable Rails/OutputSafety
    end
    javascript_include_tag hot_javascript_path(filename)
  end
end

run_once = true
# https://github.com/rspec/rspec-core/issues/1900#issuecomment-78490902
# RSpec loads spec files in alphabetical order and then runs tests in
# defined order or random order depending on your configuration.
paths = ARGV.select { |arg| arg.downcase.include? '.rb' }
last_feature_spec_path = paths.empty? ? Dir['spec/features/*'].max : File.basename(paths.last)

RSpec.configure do |config|
  config.before(:each, type: :feature, js: true) do
    # Generate and instrument assets once
    if run_once
      begin
        ENV['feature'] = 'true' # Used in hot_javascript_tag to generate separate modules
        run_once = false
        Rake::Task['generate:coverage:assets'].execute
      rescue StandardError
        Rails.application.load_tasks # Load tasks manually
        Rake::Task['generate:coverage:assets'].execute
      end
    end
  end

  config.after(:each, type: :feature, js: true) do |example|
    # Capture the coverage data in the final feature spec and write to jscoverage.json
    if example.metadata[:example_group][:absolute_file_path].end_with?(last_feature_spec_path)
      out = page.evaluate_script(
        "typeof(_$jscoverage)!='undefined' && jscoverage_serializeCoverageToJSON()"
      )
      if out.present?
        File.open(File.join(Rails.root, 'public/js_coverage/jscoverage.json'), 'w') do |f|
          f.write(out)
        end
      end
    end
  end

  config.after(:suite) do
    if ENV['feature'] == 'true'
      begin
        Rake::Task['generate:coverage:report'].execute
        Rake::Task['move:assets:to_public'].execute
      rescue StandardError
        Rails.application.load_tasks # Load tasks manually
        Rake::Task['generate:coverage:report'].execute
        Rake::Task['move:assets:to_public'].execute
      end
    end
  end
end
