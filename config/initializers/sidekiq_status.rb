expiration =  3.hours.to_i

Sidekiq.configure_client do |config|
  Sidekiq::Status.configure_client_middleware config, expiration: expiration
end

Sidekiq.configure_server do |config|
  Sidekiq::Status.configure_server_middleware config, expiration: expiration
  Sidekiq::Status.configure_client_middleware config, expiration: expiration
end
