schedule_file = "config/schedule.yml"
Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
