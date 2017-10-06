# frozen_string_literal: true

# Usage: bundle exec rake sidekiq:<task_name

namespace :sidekiq do
  CONFIG_FILE = Rails.root + 'config/sidekiq.yml'
  SIDEKIQ_CONFIG = YAML.load_file(CONFIG_FILE)
  PID_FILE = Rails.root + SIDEKIQ_CONFIG[Rails.env][:pidfile]
  LOG_FILE = Rails.root + SIDEKIQ_CONFIG[Rails.env][:logfile]

  # Stops Sidekiq process, if already running.
  desc 'Stop Sidekiq workers'
  task :stop do
    if File.exist?(PID_FILE)
      puts "Stopping sidekiq for #PID-#{File.readlines(PID_FILE).first}."
      system "sidekiqctl stop #{PID_FILE}"
    else
      puts 'Sidekiq Not Running.'
    end
  end

  # Starts sidekiq process as a daemon. All runtime logs are logged to the
  # specified logfile.
  desc 'Start Sidekiq workers'
  task :start do
    puts 'Starting Sidekiq.'
    system "bundle exec sidekiq -e #{Rails.env} -C #{CONFIG_FILE}  -P #{PID_FILE} -d -L #{LOG_FILE}"
    sleep(2)
    puts "Sidekiq started as #PID-#{File.readlines(PID_FILE).first}."
  end

  # Stops any running Sidekiq processes and starts them again with a new PID.
  desc 'Restart Sidekiq'
  task :restart do
    puts 'Restarting Sidekiq now.'
    Rake::Task['sidekiq:stop'].invoke
    Rake::Task['sidekiq:start'].invoke
  end
end
