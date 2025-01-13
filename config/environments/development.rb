Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  Paperclip.options[:command_path] = "/usr/bin"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  config.action_mailer.default_url_options = { host: ENV['dashboard_url'] }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default :charset => "utf-8"
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: ENV['mailgun_key'],
    domain: ENV['mailgun_domain'],
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  config.log_level = :debug

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Include the Ruby call site for database queries
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true
end
