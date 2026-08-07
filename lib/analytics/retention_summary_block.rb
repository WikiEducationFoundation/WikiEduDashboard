# frozen_string_literal: true

# Builds the summary block at the top of the retention predictors CSV from the
# per-student stats RetentionPredictorsCsvBuilder has already computed.
#
# Participants are split into three groups:
#
#   * Long-term Wikipedians (1000+ edits before the course began) are listed in
#     the per-student detail block but excluded from every aggregate here — the
#     report only counts them so the reader knows how many there were.
#   * Returning participants, who had already taken an earlier course, are
#     aggregated in their own column so their numbers are not read as
#     first-course outcomes.
#   * Everyone else is a first-course participant.
#
# Every aggregate is therefore reported twice, once per counted group. A group
# with no members gets blanks rather than a column of zeros.
class RetentionSummaryBlock
  SURVIVAL_THRESHOLD = 5

  HEADER = ['Summary', 'first course', 'returning participants'].freeze
  EXCLUDED_LABEL = 'long-term Wikipedians (excluded from all counts)'

  METRICS = [
    ['total editing sessions during course', :total_sessions_during],
    ['participants with no editing sessions during course', :zero_edit_participants],
    ['avg days to first independent edit', :avg_days_to_return],
    ['avg editing sessions in 30 days after course', :avg_sessions_after],
    ['participants who edited in 30 days after course', :editors_after_course],
    ['participants with 1+ edits in days 60-90', :any_survival_edits],
    ["participants with #{SURVIVAL_THRESHOLD}+ edits in days 60-90 (survivors)", :survivors]
  ].freeze

  def initialize(stats)
    @excluded = stats.select { |s| s[:long_term] }
    counted = stats.reject { |s| s[:long_term] }
    @returning, @first_time = counted.partition { |s| s[:returning] }
  end

  def rows
    [
      HEADER,
      ['participants', @first_time.size, @returning.size],
      [EXCLUDED_LABEL, @excluded.size],
      *metric_rows
    ]
  end

  private

  def metric_rows
    METRICS.map do |label, metric|
      [label, value(metric, @first_time), value(metric, @returning)]
    end
  end

  # Blank rather than zero when the group is empty, so an absent group reads as
  # "no data" instead of "no editing".
  def value(metric, group)
    return nil if group.empty?
    send(metric, group)
  end

  def total_sessions_during(stats)
    stats.sum { |s| s[:sessions_during] }
  end

  # Participants with zero editing sessions during the course. Always available,
  # since the during-course metric never depends on a not-yet-closed window.
  def zero_edit_participants(stats)
    stats.count { |s| s[:sessions_during].zero? }
  end

  def avg_days_to_return(stats)
    average(stats.map { |s| s[:days_to_return] })
  end

  def avg_sessions_after(stats)
    average(stats.map { |s| s[:sessions_after] })
  end

  # Participants who made at least one edit in the 30 days after the course.
  # Blank (nil) until the return window has closed.
  def editors_after_course(stats)
    counts = stats.map { |s| s[:sessions_after] }
    return nil if counts.any?(&:nil?)
    counts.count(&:positive?)
  end

  def any_survival_edits(stats)
    edited_in_survival_window(stats, 1)
  end

  def survivors(stats)
    edited_in_survival_window(stats, SURVIVAL_THRESHOLD)
  end

  # Participants with at least `threshold` edits in the 60-90-day survival
  # window. Blank (nil) until that window has closed.
  def edited_in_survival_window(stats, threshold)
    counts = stats.map { |s| s[:edits_60_90] }
    return nil if counts.any?(&:nil?)
    counts.count { |count| count >= threshold }
  end

  # Mean over students, rounded to one decimal. Blank (nil) when the underlying
  # metric is not yet available (its per-student values are all nil).
  def average(values)
    return nil if values.empty? || values.any?(&:nil?)
    (values.sum.to_f / values.size).round(1)
  end
end
