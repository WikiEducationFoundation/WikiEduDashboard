# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"
require_dependency "#{Rails.root}/app/services/score_ai_detection_sample"

# One chunk of a ScoreDetectorComparisonCore run: scores the next CHUNK_SIZE
# pending texts with the first detector that has any, updates the run's
# progress, and decides whether the run should stop. A chunk belonging to a run
# that has been replaced exits without saving, and a stop requested while the
# chunk was being scored takes effect when it ends. See
# ScoreDetectorComparisonCore for the run's settings and stop conditions.
class ScoreDetectorComparisonChunk
  CORE = ScoreDetectorComparisonCore

  def initialize(run, id)
    @run = run
    @id = id
  end

  def step
    return false unless current?(@run)
    return finish('stopped', 'Stopped on request') if @run['state'] == 'stopping'
    return false unless @run['state'] == 'running'

    detector, chunk = next_chunk
    return finish('finished', 'Every core text is scored') unless detector

    score_chunk(detector, chunk)
  rescue *AiDetector.model_mismatch_errors => e
    finish('stopped', "#{e.class}: #{e.message}")
  rescue StandardError => e
    finish('stopped', "#{e.class}: #{e.message}")
    raise
  end

  private

  def current?(run)
    run['id'].present? && run['id'] == @id
  end

  # The first detector, in run order, with texts left to score, and its next chunk.
  # Texts that failed during this run wait for the next start.
  def next_chunk
    units = AiDetectionSample.where(id: @run['unit_ids']).select(CORE::PENDING_COLUMNS)
                             .order(:id).to_a
    @run['detectors'].each do |key|
      detector = AiDetector.for(key)
      failed = @run.dig('phases', key, 'failed_ids').to_a
      pending = ScoreAiDetectionSample.pending_units(units, detector)
                                      .reject { |unit| failed.include?(unit.id) }
                                      .first(CORE::CHUNK_SIZE)
      return [detector, AiDetectionSample.where(id: pending.map(&:id)).order(:id).to_a] if
        pending.any?
    end
    nil
  end

  def score_chunk(detector, chunk)
    phase = (@run['phases'][detector.key] ||= new_phase(detector))
    report = ScoreAiDetectionSample.new(units: chunk, detectors: [detector.key])
                                   .report[detector.key]
    record(detector, phase, chunk, report)
    reason = stop_reason(detector, phase)
    return finish('stopped', reason) if reason

    save_progress
  end

  # Saves the chunk's progress unless the run was replaced or stopped meanwhile.
  def save_progress
    stored = CORE.run
    return false unless current?(stored)
    return finish('stopped', 'Stopped on request') if stored['state'] == 'stopping'

    CORE.save_run(@run)
    true
  end

  def new_phase(detector)
    { 'started_at' => Time.zone.now.iso8601,
      'start_balance' => (CORE.originality_balance if metered?(detector)),
      'scored' => 0, 'failed' => 0, 'failed_ids' => [], 'estimated_credits' => 0 }
  end

  def record(detector, phase, chunk, report)
    scored = RevisionAiScore.where(sample_id: chunk.map(&:id), check_type: detector.key)
                            .where.not(avg_ai_likelihood: nil).pluck(:sample_id).to_set
    scored_units, failed_units = chunk.partition { |unit| scored.include?(unit.id) }
    phase['failed_ids'] += failed_units.map(&:id)
    phase['estimated_credits'] += detector.estimated_credits(scored_units.map(&:word_count)).to_i
    tally(phase, report)
  end

  def tally(phase, report)
    phase['scored'] += report[:scored]
    phase['failed'] += report[:failed]
    @run['scored'] += report[:scored]
    @run['failed'] += report[:failed]
    @run['failures_in_a_row'] =
      report[:scored].positive? ? 0 : @run['failures_in_a_row'] + report[:failed]
  end

  def stop_reason(detector, phase)
    if @run['failures_in_a_row'] >= CORE::FAILURE_LIMIT
      return "#{CORE::FAILURE_LIMIT} failed calls in a row; see the failed rows' details"
    end
    if phase['failed'] >= CORE::MAX_FAILURES
      return "#{phase['failed']} failed #{detector.key} calls"
    end
    return unless metered?(detector)

    balance = CORE.originality_balance
    spent = @run['start_balance'] - balance
    if spent > @run['max_originality_credits']
      return "Spent #{spent} Originality credits, over max_originality_credits"
    end

    billing_reason(detector, phase, balance)
  end

  # Checked once per detector, after its first BILLING_CHECK_UNITS texts.
  def billing_reason(detector, phase, balance)
    return if phase['scored'] < CORE::BILLING_CHECK_UNITS || phase['billing_checked']

    phase['billing_checked'] = true
    spent = phase['start_balance'] - balance
    return if spent <= phase['estimated_credits'] * CORE::BILLING_TOLERANCE

    "#{detector.key} spent #{spent} credits on #{phase['scored']} texts, estimated " \
      "#{phase['estimated_credits']}; check its price before starting again"
  end

  def metered?(detector)
    CORE.metered?(detector.key)
  end

  # Records why the run ended, unless another run has replaced it.
  def finish(state, message)
    return false unless current?(CORE.run)

    CORE.save_run(@run.merge('state' => state, 'message' => message))
    false
  end
end
