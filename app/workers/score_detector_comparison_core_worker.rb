# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/score_detector_comparison_core"

# Scores one chunk of the detector comparison core texts, then queues the next
# chunk, so the run shares the default queue with production AI checks instead
# of holding it for hours. Started by ScoreDetectorComparisonCore.start; the
# run's state lives in a Setting, so a lost job is resumed by starting again.
class ScoreDetectorComparisonCoreWorker
  include Sidekiq::Worker
  # Each call bills, and the service records why a chunk failed, so no retries.
  # The lock is released when a job starts, so it can queue its successor.
  sidekiq_options retry: 0, lock: :until_executing

  def perform
    self.class.perform_async if ScoreDetectorComparisonCore.step
  end
end
