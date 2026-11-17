# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"
require_dependency "#{Rails.root}/app/services/score_ai_detection_sample"
require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/summarize_known_human_texts"

# Scores the core texts of the detector comparison with the current detectors
# (AiDetector.keys) in the background, so a new detector or model version can be
# compared with everything the earlier ones scored. The core texts are the units
# behind the comparison page: the known-human texts and the topics dataset. Each
# distinct text is scored once; results on identical copies count for every unit
# that holds the text (CollectDetectorComparisonScores).
#
# In a production console:
#   ScoreDetectorComparisonCore.plan    # pending texts and estimated credits per detector
#   ScoreDetectorComparisonCore.start(max_originality_credits: 40_000)  # queue the run
#   ScoreDetectorComparisonCore.status  # progress, or why the run stopped
#   ScoreDetectorComparisonCore.stop    # stop after the current chunk
#
# The run is one ScoreDetectorComparisonCoreWorker job at a time, each scoring
# CHUNK_SIZE texts and queuing the next, so production AI checks on the same
# queue run in between. Detectors run one after another in the order given
# (registry order by default, which puts Originality 5.0 Max last). The run
# stops, recording why in its status, when:
# - a pinned detector's vendor answers with another model version;
# - FAILURE_LIMIT calls in a row fail;
# - Originality credits spent since the start exceed max_originality_credits;
# - after BILLING_CHECK_UNITS texts of an Originality detector, it has spent more
#   than BILLING_TOLERANCE times its estimate. Originality lists 5.0 Max at ten
#   times 5.0's price, although the API charged the same in a first probe.
# Starting again continues with the texts not yet scored. To analyze the results
# locally, export them with ExportDetectorComparisonScores.
class ScoreDetectorComparisonCore
  SETTING_KEY = 'detector_comparison_core_run'
  CHUNK_SIZE = 10
  FAILURE_LIMIT = 10
  BILLING_CHECK_UNITS = 10
  BILLING_TOLERANCE = 2
  # Columns needed to tell which texts are pending; the chunk being scored loads in full.
  PENDING_COLUMNS = %i[id word_count].freeze

  # The core texts, one unit per distinct text.
  def self.units
    all = SummarizeKnownHumanTexts.units.select(:id, :text_sha256).to_a +
          SummarizeDetectorComparison.units
    all.uniq(&:id).group_by(&:text_sha256).values.map { |copies| copies.min_by(&:id) }
       .sort_by(&:id)
  end

  def self.plan(detectors: AiDetector.keys)
    ids = units.map(&:id)
    ScoreAiDetectionSample.new(units: AiDetectionSample.where(id: ids).order(:id).to_a,
                               detectors:, dry_run: true).report
  end

  def self.start(max_originality_credits:, detectors: AiDetector.keys)
    unselectable = detectors.reject { |key| AiDetector.selectable?(key) }
    raise ArgumentError, "not offered for comparison scoring: #{unselectable}" if unselectable.any?

    save_run('state' => 'running', 'detectors' => detectors, 'unit_ids' => units.map(&:id),
             'max_originality_credits' => max_originality_credits,
             'start_balance' => originality_balance, 'started_at' => Time.zone.now.iso8601,
             'scored' => 0, 'failed' => 0, 'failures_in_a_row' => 0, 'phases' => {},
             'message' => nil)
    ScoreDetectorComparisonCoreWorker.perform_async
    status
  end

  def self.stop
    save_run(run.merge('state' => 'stopping')) if run['state'] == 'running'
    status
  end

  # The run's progress and settings, without its list of unit ids.
  def self.status
    run.except('unit_ids')
  end

  def self.run
    Setting.find_by(key: SETTING_KEY)&.value || {}
  end

  def self.save_run(value)
    Setting.find_or_create_by(key: SETTING_KEY)
           .update!(value: value.merge('updated_at' => Time.zone.now.iso8601))
  end

  def self.originality_balance
    OriginalityApi.credit_balance
  end

  # Scores one chunk; the worker calls this. Returns true when another chunk
  # should be queued.
  def self.step
    new(run).step
  end

  def initialize(run)
    @run = run
  end

  def step
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

  # The first detector, in run order, with texts left to score, and its next chunk.
  def next_chunk
    units = AiDetectionSample.where(id: @run['unit_ids']).select(PENDING_COLUMNS).order(:id).to_a
    @run['detectors'].each do |key|
      detector = AiDetector.for(key)
      pending = ScoreAiDetectionSample.pending_units(units, detector).first(CHUNK_SIZE)
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

    self.class.save_run(@run)
    true
  end

  def new_phase(detector)
    { 'started_at' => Time.zone.now.iso8601,
      'start_balance' => (self.class.originality_balance if metered?(detector)),
      'scored' => 0, 'estimated_credits' => 0 }
  end

  def record(detector, phase, chunk, report)
    scored = RevisionAiScore.where(sample_id: chunk.map(&:id), check_type: detector.key)
                            .where.not(avg_ai_likelihood: nil).pluck(:sample_id).to_set
    words = chunk.select { |unit| scored.include?(unit.id) }.map(&:word_count)
    phase['scored'] += report[:scored]
    phase['estimated_credits'] += detector.estimated_credits(words).to_i
    tally(report)
  end

  def tally(report)
    @run['scored'] += report[:scored]
    @run['failed'] += report[:failed]
    @run['failures_in_a_row'] =
      report[:scored].positive? ? 0 : @run['failures_in_a_row'] + report[:failed]
  end

  def stop_reason(detector, phase)
    if @run['failures_in_a_row'] >= FAILURE_LIMIT
      return "#{FAILURE_LIMIT} failed calls in a row; see the failed rows' details"
    end
    return unless metered?(detector)

    balance = self.class.originality_balance
    spent = @run['start_balance'] - balance
    if spent > @run['max_originality_credits']
      return "Spent #{spent} Originality credits, over max_originality_credits"
    end

    billing_reason(detector, phase, balance)
  end

  # Checked once per detector, after its first BILLING_CHECK_UNITS texts.
  def billing_reason(detector, phase, balance)
    return if phase['scored'] < BILLING_CHECK_UNITS || phase['billing_checked']

    phase['billing_checked'] = true
    spent = phase['start_balance'] - balance
    return if spent <= phase['estimated_credits'] * BILLING_TOLERANCE

    "#{detector.key} spent #{spent} credits on #{phase['scored']} texts, estimated " \
      "#{phase['estimated_credits']}; check its price before starting again"
  end

  def metered?(detector)
    detector.vendor.balance_reader.present?
  end

  def finish(state, message)
    self.class.save_run(@run.merge('state' => state, 'message' => message))
    false
  end
end
