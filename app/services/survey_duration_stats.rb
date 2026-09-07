# frozen_string_literal: true

#= Computes survey completion-time statistics from a single data load.
#
# For a single survey (per-survey results page):
#   stats = SurveyDurationStats.new(survey)
#   stats.average          # => "4m 32s"
#   stats.median           # => "3m 18s"
#   stats.completion_rate  # => "72.5% (29/40)"
#
# For batch average across many surveys (admin list pages):
#   SurveyDurationStats.batch_averages([survey1, survey2, ...])
#   # => { survey1.id => "4m 32s", survey2.id => "--" }
#
class SurveyDurationStats
  attr_reader :durations

  def initialize(survey)
    @survey = survey
    @durations = load_durations
  end

  # --- Formatted stat accessors ------------------------------------------------

  def average
    return '--' if durations.empty?
    format_duration(durations.sum / durations.size)
  end

  def median
    return '--' if durations.empty?
    sorted = durations.sort
    mid = sorted.length / 2
    value = sorted.length.odd? ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2.0).to_i
    format_duration(value)
  end

  def fastest
    return '--' if durations.empty?
    format_duration(durations.min)
  end

  def slowest
    return '--' if durations.empty?
    format_duration(durations.max)
  end

  def completion_rate
    total_started = SurveySession.where(survey: @survey).count
    return '--' if total_started.zero?
    total_completed = SurveySession.where(survey: @survey).completed.count
    percent = (total_completed.to_f / total_started * 100).round(1)
    "#{percent}% (#{total_completed}/#{total_started})"
  end

  def distribution
    return {} if durations.empty?
    buckets = { '0-1 min' => 0, '1-2 min' => 0, '2-5 min' => 0,
                '5-10 min' => 0, '10-20 min' => 0, '20+ min' => 0 }
    durations.each do |d|
      case d
      when 0..60 then buckets['0-1 min'] += 1
      when 61..120 then buckets['1-2 min'] += 1
      when 121..300 then buckets['2-5 min'] += 1
      when 301..600 then buckets['5-10 min'] += 1
      when 601..1200 then buckets['10-20 min'] += 1
      else buckets['20+ min'] += 1
      end
    end
    buckets
  end

  # --- Batch helper for admin list pages --------------------------------------

  # Returns { survey_id => formatted_avg_string } using a single aggregate query.
  def self.batch_averages(surveys)
    survey_ids = surveys.map(&:id)
    return {} if survey_ids.empty?

    averages = SurveySession
               .where(survey_id: survey_ids)
               .completed
               .group(:survey_id)
               .average(duration_sql_expression)

    survey_ids.index_with do |id|
      avg = averages[id]
      avg ? format_duration(avg.to_i) : '--'
    end
  end

  # --- Private ----------------------------------------------------------------

  private

  # Loads all completed durations for the survey in a single query.
  def load_durations
    SurveySession
      .where(survey: @survey)
      .completed
      .pluck(Arel.sql(self.class.duration_sql_expression.to_s))
      .compact
  end

  def format_duration(seconds)
    self.class.format_duration(seconds)
  end

  def self.format_duration(seconds)
    return '--' if seconds.nil?
    if seconds >= 3600
      "#{seconds / 3600}h #{(seconds % 3600) / 60}m"
    elsif seconds >= 60
      "#{seconds / 60}m #{seconds % 60}s"
    else
      "#{seconds}s"
    end
  end

  def self.duration_sql_expression
    Arel.sql('TIMESTAMPDIFF(SECOND, started_at, completed_at)')
  end
end
