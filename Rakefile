# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'tasks/newrelic'

# Given a pid file that contains the pid of a process, check whether it is
# running. If not, delete the file and return false.
def pid_file_process_running?(pid_file)
  pid = File.read(pid_file).to_i
  return true if Process.kill 0, pid
rescue Errno::ESRCH
  Rails.logger.warn ("Process #{pid} not found. Deleting #{pid_file}")
  File.delete pid_file
  return false
end

Rails.application.load_tasks
