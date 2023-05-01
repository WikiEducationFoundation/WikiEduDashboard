# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %(app lib config test spec feature)

## Uncomment to clear the screen before every task
# clearing :on

guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'
  helper = Guard::Bundler::Verify.new

  files = ['Gemfile']
  files += Dir['*.gemspec'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

guard 'rails', environment: 'development', host: ENV['RAILS_HOST'] || 'localhost' do
  watch('Gemfile.lock')
  watch(%r{^(config|lib)/(?!locales/|i18n-js.yml).*})
  watch(%r{training_content/.+\.yml})
end

# Note: The cmd option is now required due to the increasing number of ways
#       rspec may be run, below are examples of the most common uses.
#  * bundler: 'bundle exec rspec'
#  * bundler binstubs: 'bin/rspec'
#  * spring: 'bin/rspec' (This will use spring if running and you have
#                          installed the spring binstubs per the docs)
#  * zeus: 'zeus rspec' (requires the server to be started separately)
#  * 'just' rspec: 'rspec'

guard :rspec, cmd: 'bundle exec rspec' do
  require 'ostruct'

  # Generic Ruby apps
  rspec = OpenStruct.new
  rspec.spec = ->(m) { "spec/#{m}_spec.rb" }
  rspec.spec_dir = 'spec'
  rspec.spec_helper = "spec/spec_helper.rb"

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| rspec.spec.("lib/#{m[1]}") }
  watch(rspec.spec_helper)      { rspec.spec_dir }

  # Rails example
  rails = OpenStruct.new
  rails.app = %r{^app/(.+)\.rb$}
  rails.views_n_layouts = %r{^app/(.*)(\.erb|\.haml|\.slim)$}
  rails.controllers = %r{^app/controllers/(.+)_controller\.rb$}
  rails.routes = 'config/routes.rb'
  rails.app_controller = 'app/controllers/application_controller.rb'
  rails.spec_helper = 'spec/rails_helper.rb'
  rails.spec_support = %r{^spec/support/(.+)\.rb$}
  rails.views = %r{^app/views/(.+)/.*\.(erb|haml|slim)$}

  watch(rails.app) { |m| rspec.spec.(m[1]) }
  watch(rails.views_n_layouts) { |m| rspec.spec.("#{m[1]}#{m[2]}") }
  watch(rails.controllers) do |m|
    [
      rspec.spec.("routing/#{m[1]}_routing"),
      rspec.spec.("controllers/#{m[1]}_controller"),
      rspec.spec.("acceptance/#{m[1]}")
    ]
  end

  watch(rails.spec_support)    { rspec.spec_dir }
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.routes)          { 'spec/routing' }
  watch(rails.app_controller)  { 'spec/controllers' }

  # Capybara features specs
  watch(rails.views)     { |m| rspec.spec.("features/#{m[1]}") }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) do |m|
    Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance'
  end
end


guard :"i18n-js", run_on_start: false, config_file: "./config/i18n-js.yml", require_file: "./config/environment.rb" do
  watch(%r{^(app|config)/locales/.+\.(yml|po)$})
  watch(%r{^config/i18n-js.yml$})
end
