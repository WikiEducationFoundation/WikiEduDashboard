# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_summary_block"

# Aggregates stored RetentionStat rows — one course's, or a whole campaign's —
# into the figures the report card shows.
#
# Long-term Wikipedians (500+ edits before the course) are counted in
# `participants` and `long_term_wikipedians` and left out of everything else,
# the same rule RetentionSummaryBlock applies to the CSV: an established editor
# who keeps editing is not a retention outcome.
#
# Each post-course metric is aggregated over the rows where it has been computed
# (its window had closed when the row was stored) and is nil when there are
# none, so a course still inside a window shows a blank rather than a zero. For
# a single course every row was computed at once, so that is all-or-nothing;
# for a campaign it means "over the courses that have got that far".
class RetentionMetrics
  SURVIVAL_THRESHOLD = RetentionSummaryBlock::SURVIVAL_THRESHOLD

  def initialize(stats)
    @stats = stats.to_a
    @counted = @stats.reject(&:long_term_wikipedian)
  end

  def participants
    @stats.size
  end

  # nil rather than 0 when nothing has been computed: the count is unknown.
  def long_term_wikipedians
    return nil if @stats.empty?
    @stats.count(&:long_term_wikipedian)
  end

  def counted_participants
    @counted.size
  end

  def sessions_during
    return nil if @counted.empty?
    @counted.sum(&:sessions_during)
  end

  def avg_sessions_during
    average(@counted.map(&:sessions_during))
  end

  def zero_edit_participants
    return nil if @counted.empty?
    @counted.count { |s| s.sessions_during.zero? }
  end

  def editors_after_course
    rows = computed(:sessions_after)
    return nil if rows.empty?
    rows.count { |s| s.sessions_after.positive? }
  end

  # Editors after the course as a percentage of those who edited during it
  # (the spreadsheet's `M / (D − H)`), over the rows whose return window has
  # closed. nil when nobody edited during the course. The numerator is not
  # limited to the denominator's editors, so a participant who edited only after
  # the course can push this past 100%, as it does in the spreadsheet.
  def pct_active_editors_after
    rows = computed(:sessions_after)
    active = rows.count { |s| s.sessions_during.positive? }
    return nil if active.zero?
    (rows.count { |s| s.sessions_after.positive? } * 100.0 / active).round(1)
  end

  def avg_days_to_return
    average(computed(:days_to_return).map(&:days_to_return))
  end

  def avg_sessions_after
    average(computed(:sessions_after).map(&:sessions_after))
  end

  def any_survival_edits
    survival_count(1)
  end

  def any_survival_edits_returning
    survival_count(1, returning: true)
  end

  def survivors
    survival_count(SURVIVAL_THRESHOLD)
  end

  def survivors_returning
    survival_count(SURVIVAL_THRESHOLD, returning: true)
  end

  private

  # Counted rows for which `metric` has been computed.
  def computed(metric)
    @counted.select { |s| s.public_send(metric) }
  end

  def survival_count(threshold, returning: false)
    rows = computed(:edits_60_90)
    return nil if rows.empty?
    rows = rows.select(&:returning?) if returning
    rows.count { |s| s.edits_60_90 >= threshold }
  end

  def average(values)
    return nil if values.empty?
    (values.sum.to_f / values.size).round(1)
  end
end
