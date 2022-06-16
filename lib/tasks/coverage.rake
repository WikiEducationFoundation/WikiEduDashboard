# frozen_string_literal: true

namespace :generate do
  desc 'Generates coverage report'
  task :coverage do
    # rubocop:disable Layout/LineLength
    system('npx nyc report --reporter=html --reporter=lcov --reporter=text-summary --report-dir=public/js_coverage')
    puts 'You can view the report at http://localhost:3000/js_coverage/index.html after running "rails s"'
    # rubocop:enable Layout/LineLength
  end
end
