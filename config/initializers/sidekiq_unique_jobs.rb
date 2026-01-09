require "sidekiq/middleware/current_attributes"

# Use to_prepare to ensure Current class is loaded
Rails.application.config.to_prepare do
  # Persist Current attributes across Sidekiq Jobs
  # Source: https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/middleware/current_attributes.rb
  Sidekiq::CurrentAttributes.persist(SidekiqJobContext)
end

SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test? # turn it off for tests
  config.lock_ttl = nil # Do not expire locks, by default
  config.lock_info = true
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end


