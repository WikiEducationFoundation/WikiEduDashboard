module SurveysAnalyticsHelper

  def survey_status(survey)
    assignments = SurveyAssignment.published.where(survey_id: survey.id)
    return "In Use (#{assignments.count})" if !assignments.empty?
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
    return "--" if model.versions.empty?
    user = User.find(model.versions.last.whodunnit)
    return user.username if !user.nil?
  end
end
