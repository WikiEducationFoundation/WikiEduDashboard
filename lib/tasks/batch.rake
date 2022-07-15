# frozen_string_literal: true

require 'action_view'

namespace :batch do
  desc 'Pause updates'
  task pause: :environment do
    pid_file = 'tmp/batch_pause.pid'
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
    Sentry.capture_message 'Updates paused.', level: 'warning'
  end

  desc 'Resume updates'
  task resume: :environment do
    pid_file = 'tmp/batch_pause.pid'
    FileUtils.rm_rf pid_file
    Sentry.capture_message 'Updates resumed.', level: 'warning'
  end
end
