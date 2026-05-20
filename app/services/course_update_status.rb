# frozen_string_literal: true

require 'sidekiq/api'

# Reads in-flight update progress for a course from sidekiq-status.
# Scans Sidekiq::WorkSet for a CourseDataUpdateWorker job whose args
# include the course id, then returns the progress fields stored by
# UpdateProgressReporter. Returns { running: false } when nothing is
# in-flight for the course.
class CourseUpdateStatus
  attr_reader :result

  def initialize(course)
    @course = course
    @result = fetch
  end

  private

  def fetch
    found = find_running_job
    return { running: false } unless found

    payload, run_at = found
    status = Sidekiq::Status.get_all(payload['jid'])
    build_result(payload, run_at, status)
  end

  def build_result(payload, run_at, status)
    {
      running: true,
      jid: payload['jid'],
      queue: payload['queue'],
      run_at: run_at.to_i,
      started_at: integer_field(status, 'started_at'),
      phase: status['phase'],
      phase_started_at: integer_field(status, 'phase_started_at'),
      at: integer_field(status, 'at'),
      total: integer_field(status, 'total'),
      pct_complete: integer_field(status, 'pct_complete'),
      message: status['message'].presence,
      updated_at: integer_field(status, 'updated_at')
    }
  end

  def integer_field(status, key)
    value = status[key]
    value.present? ? value.to_i : nil
  end

  def find_running_job
    Sidekiq::WorkSet.new.each do |_pid, _tid, work|
      payload = JSON.parse(work.payload)
      next unless payload['class'] == 'CourseDataUpdateWorker'
      next unless Array(payload['args']).include?(@course.id)
      return [payload, work.run_at]
    end
    nil
  end
end
