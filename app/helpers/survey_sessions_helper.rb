# frozen_string_literal: true

module SurveySessionsHelper
  # --- Per-survey helpers (used on the results page) --------------------------

  def average_duration(survey)
    survey_stats_for(survey).average
  end

  def median_duration(survey)
    survey_stats_for(survey).median
  end

  def fastest_duration(survey)
    survey_stats_for(survey).fastest
  end

  def slowest_duration(survey)
    survey_stats_for(survey).slowest
  end

  def completion_rate(survey)
    survey_stats_for(survey).completion_rate
  end

  def duration_distribution(survey)
    survey_stats_for(survey).distribution
  end

  # --- Batch helper (used on admin list pages) --------------------------------
  # Controllers preload @survey_avg_durations via
  # SurveyDurationStats.batch_averages. The view reads from the hash.

  def batch_average_duration(survey)
    unless defined?(@survey_avg_durations) && @survey_avg_durations
      return average_duration(survey)
    end
    @survey_avg_durations[survey.id] || '--'
  end

  private

  def survey_stats_for(survey)
    # Reuse the controller-set instance when available (results page).
    if defined?(@survey_stats) && @survey_stats&.durations && @survey_stats
      return @survey_stats
    end

    # Fallback: build a one-off instance.
    SurveyDurationStats.new(survey)
  end
end
