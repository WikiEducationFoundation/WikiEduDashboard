require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WikiEduDashboard
  class Application < Rails::Application
    config.autoload_paths += Dir[Rails.root.join("app", "models", "{*/}")]

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: false,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    ## NOTE - LOCALES with hyphens creates and error when exporting translation files
    ## currently can't add :ku-latn, :roa-tara, or :zh-hans
    # config.i18n.available_locales = [:en, :de, :bcl, :de, :es, :ja, :ksh, :lb, :nl, :pl, :pt, :qqq, :ru, :ur]


    # Fallback to default locale when messages are missing.
    config.i18n.fallbacks = true

    require "#{Rails.root}/config/cldr_pluralization"
    I18n::Backend::Simple.send(:include, I18n::Backend::CldrPluralization)

    # Set fallback locale to en, which is the source locale.
    config.i18n.fallbacks = [:en]

    # Disables native processing of Sass and Coffeescript
    config.assets.enabled = false

    # Use custom error pages (like 404) instead of Rails defaults
    config.exceptions_app = self.routes

    # Rails cache with dalli / memcached
    config.cache_store = :dalli_store, nil, { pool_size: 5, expires_in: 7.days, compress: false, value_max_bytes: 1024 * 1024 * 4 }

    # Skylight performance monitoring
    config.skylight.environments += ['staging']

    # Allows for embedding course stats
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/embed/course_stats/*/*', :headers => :any, :methods => [:get, :options]
      end
    end
  end
end
