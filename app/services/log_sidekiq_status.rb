# frozen_string_literal: true

class LogSidekiqStatus
  SLEEP_TIME_IN_SECONDS = 60

  def initialize(store)
    @store = store
    # The number of times the process went to sleep
    @sleep_count = 0
  end

  def pause_until_no_backup
    pause until Backup.current_backup.nil?
    @store.call phase: 'woke_up'
  end

  private

  def pause
    @sleep_count += 1
    @store.call phase: "sleeping_#{@sleep_count}"
    sleep SLEEP_TIME_IN_SECONDS
  end
end
