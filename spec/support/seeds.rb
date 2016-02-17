RSpec.configure do |config|
  config.before(:suite) do
    Wiki.create(language: ENV['wiki_language'], project: 'wikipedia')
    Cohort.create(title: ENV['default_cohort'])
  end
end
