require 'action_view'

module BatchUpdateLogging
  include ActionView::Helpers::DateHelper

  DAILY_UPDATE_PID_FILE = 'tmp/batch_update_daily.pid'.freeze
  CONSTANT_UPDATE_PID_FILE = 'tmp/batch_update_constantly.pid'.freeze
  PAUSE_UPDATES_FILE = 'tmp/batch_pause.pid'.freeze
  SLEEP_FILE = 'tmp/batch_sleep_10.pid'.freeze

  def setup_logger
    $stdout.sync = true
    logger = Logger.new $stdout
    logger.level = Figaro.env.cron_log_debug ? Logger::DEBUG : Logger::INFO
    logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    Rails.logger = logger
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

  def updates_paused?
    return true if File.exist? PAUSE_UPDATES_FILE
    false
  end

  def constant_update_running?
    pid_file_process_running?(CONSTANT_UPDATE_PID_FILE)
  end

  def daily_update_running?
    pid_file_process_running?(DAILY_UPDATE_PID_FILE)
  end

  def update_waiting_to_run?
    pid_file_process_running?(SLEEP_FILE)
  end
end
