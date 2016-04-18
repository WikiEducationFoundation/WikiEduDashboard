module SurveysAnalyticsHelper
  def survey_status(survey, count = false)
    assignments = SurveyAssignment.published.where(survey_id: survey.id)
    return assignments.count if count
    return "In Use (#{assignments.count})" unless assignments.empty?
    return '--'
  end

  def survey_question_stats(survey)
    question_groups = survey.rapidfire_question_groups
    qg_count = question_groups.count
    question_total = 0
    question_groups.collect { |qg| question_total += qg.questions.count }
    "#{qg_count} | #{question_total}"
  end

  def survey_author(model)
    return '--' if model.versions.empty?
    user = User.find(model.versions.last.whodunnit)
    return user.username unless user.nil?
  end

  def question_group_status(question_group)
    survey_question_groups = SurveysQuestionGroup.where(
      rapidfire_question_group_id: question_group.id
    )

    return '--' if survey_question_groups.empty?
    total_published_surveys = 0
    survey_question_groups.each do |sqg|
      next if sqg.survey.nil?
      total_published_surveys += survey_status(sqg.survey, true)
    end
    return '--' if total_published_surveys == 0
    return "In Use (#{total_published_surveys})"
  end

  def assignment_response(survey_assignment)
    completed = survey_assignment.survey_notifications.completed.length
    notified = survey_assignment.survey_notifications.length
    # total_potential = survey_assignment.total_notifications
    percent = 0
    percent = (completed.to_f / notified.to_f) * 100 if completed > 0
    "#{percent.round(2)}% (#{completed}/#{notified})"
  end
end
