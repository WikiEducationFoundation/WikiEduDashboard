# frozen_string_literal: true

module SurveysAnalyticsHelper
  def survey_status(survey, count = false)
    assignments = survey.survey_assignments.select(&:published?)
    return assignments.size if count
    return "In Use (#{assignments.size})" unless assignments.empty?
    '--'
  end

  def survey_question_stats(survey)
    question_groups = survey.rapidfire_question_groups
    qg_count = question_groups.size
    question_total = 0
    question_groups.collect { |qg| question_total += qg.questions.size }
    "#{qg_count} | #{question_total}"
  end

  def survey_author(model)
    return '--' if model.versions.empty? || model.versions.last.whodunnit.nil?
    user = User.find(model.versions.last.whodunnit)
    return user.username unless user.nil?
  end

  def question_group_survey_author(version)
    return '--' if version.blank? || version.whodunnit.nil?
    user = User.find(version.whodunnit)
    return user.username unless user.nil?
  end

  def question_group_status(survey_question_groups, surveys)
    return '--' if survey_question_groups.blank?
    total_published_surveys = 0
    survey_question_groups.each do |sqg|
      next if surveys[sqg.survey_id].blank?
      total_published_surveys += survey_status(surveys[sqg.survey_id].first, true)
    end
    return '--' if total_published_surveys.zero?
    return "In Use (#{total_published_surveys})"
  end

  def assignment_response(survey_assignment)
    completed = survey_assignment.survey_notifications.count(&:completed)
    notified = survey_assignment.survey_notifications.length
    response_summary_string(completed, notified)
  end

  def assignment_dismissal(survey_assignment)
    dismissed = survey_assignment.survey_notifications.count { |n| !n.completed && n.dismissed }
    notified = survey_assignment.survey_notifications.length
    response_summary_string(dismissed, notified)
  end

  def survey_response(survey)
    completed = 0
    survey.survey_assignments.each do |sa|
      completed += sa.survey_notifications.completed.count
    end
    notified = 0
    survey.survey_assignments.each do |sa|
      notified += sa.survey_notifications.count
    end
    response_summary_string(completed, notified)
  end

  def response_summary_string(action_taken, notified)
    percent = 0
    percent = (action_taken / notified.to_f) * 100 if action_taken.positive?
    "#{percent.round(2)}% (#{action_taken}/#{notified})"
  end
end
