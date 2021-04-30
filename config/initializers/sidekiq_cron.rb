schedule_file = "config/schedule.yml"
begin
  Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file) if defined?(Rails::Server)
rescue
  puts 'Could not enqueue sidekiq-cron schedule.'
end
