# frozen_string_literal: true

require 'action_view'

module BatchUpdateLogging
  include ActionView::Helpers::DateHelper

  UPDATE_PID_FILES = {
    daily: 'tmp/batch_update_daily.pid',
    constant: 'tmp/batch_update_constantly.pid',
    views: 'tmp/batch_update_views.pid',
    survey: 'tmp/batch_update_surveys.pid',
    pause: 'tmp/batch_pause.pid',
    sleep: 'tmp/batch_sleep_10.pid'
  }.freeze

  def setup_logger
    $stdout.sync = true
    logger = Logger.new $stdout
    logger.level = Figaro.env.cron_log_debug ? Logger::DEBUG : Logger::INFO
    logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    Rails.logger = logger
    @sentry_logs = []
  end

  def run_update_with_pid_files(type)
    create_pid_file(type)
    run_update # implemented by each update class
  ensure
    delete_pid_file(type)
  end

  # Given a pid file that contains the pid of a process, check whether it is
  # running. If not, delete the file and return false.
  def pid_file_process_running?(pid_file)
    return false unless File.exist? pid_file
    Rails.logger.warn "#{pid_file} appears to be running."
    pid = File.read(pid_file).to_i
    return true if Process.kill 0, pid
  rescue Errno::ESRCH
    Rails.logger.warn "Process #{pid} not found. Deleting #{pid_file}."
    File.delete pid_file
    return false
  end

  def create_pid_file(type)
    File.open(UPDATE_PID_FILES[type], 'w') { |f| f.puts Process.pid }
  end

  def delete_pid_file(type)
    File.delete UPDATE_PID_FILES[type] if File.exist? UPDATE_PID_FILES[type]
  end

  def updates_paused?
    return true if File.exist? UPDATE_PID_FILES[:pause]
    false
  end

  def update_running?(type)
    pid_file_process_running? UPDATE_PID_FILES[type]
  end

  def update_waiting_to_run?
    pid_file_process_running? UPDATE_PID_FILES[:sleep]
  end

  def log_message(message)
    Rails.logger.debug message
    @sentry_logs << "#{Time.zone.now} - #{message}"
    Raven.capture_message(message, level: 'warn', extra: { logs: @sentry_logs }) if debug?
  end

  def log_start_of_update(message)
    @start_time = Time.zone.now
    Rails.logger.info message
  end

  def log_end_of_update(message)
    @end_time = Time.zone.now
    log_message 'Update finished'
    total_time = distance_of_time_in_words(@start_time, @end_time)
    Rails.logger.info "#{message} Time: #{total_time}."
    UpdateLog.log_update(@end_time.to_datetime) if self.class.to_s == 'ConstantUpdate'
    Raven.capture_message message,
                          level: 'info',
                          tags: { update_time: total_time },
                          extra: { exact_update_time: (@end_time - @start_time),
                                   logs: @sentry_logs }
  end

  def debug?
    ENV['update_debug'] == 'true'
  end
end
