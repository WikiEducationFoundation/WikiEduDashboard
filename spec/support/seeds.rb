RSpec.configure do |config|
  config.before(:suite) do
    Wiki.create(language: ENV['wiki_language'], project: 'wikipedia')
  end
end
