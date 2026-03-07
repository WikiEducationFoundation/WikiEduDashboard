# frozen_string_literal: true

module SurveyDurationsHelper
  def average_duration(survey)
    times = SurveyCompletionTime.where(survey: survey).completed
    return '--' if times.empty?
    avg = times.average(:duration_in_seconds).to_i
    format_duration(avg)
  end

  def median_duration(survey)
    durations = completed_durations(survey)
    return '--' if durations.empty?
    sorted = durations.sort
    mid = sorted.length / 2
    median = sorted.length.odd? ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2.0).to_i
    format_duration(median)
  end

  def fastest_duration(survey)
    durations = completed_durations(survey)
    return '--' if durations.empty?
    format_duration(durations.min)
  end

  def slowest_duration(survey)
    durations = completed_durations(survey)
    return '--' if durations.empty?
    format_duration(durations.max)
  end

  def completion_rate(survey)
    total_started = SurveyCompletionTime.where(survey: survey).count
    return '--' if total_started.zero?
    total_completed = SurveyCompletionTime.where(survey: survey).completed.count
    percent = (total_completed.to_f / total_started * 100).round(1)
    "#{percent}% (#{total_completed}/#{total_started})"
  end

  def duration_distribution(survey)
    durations = completed_durations(survey)
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

  private

  def format_duration(seconds)
    return '--' if seconds.nil?
    if seconds >= 3600
      "#{seconds / 3600}h #{(seconds % 3600) / 60}m"
    elsif seconds >= 60
      "#{seconds / 60}m #{seconds % 60}s"
    else
      "#{seconds}s"
    end
  end

  def completed_durations(survey)
    SurveyCompletionTime.where(survey: survey)
                        .completed
                        .pluck(:duration_in_seconds)
                        .compact
  end
end
