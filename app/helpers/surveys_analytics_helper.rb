module SurveysAnalyticsHelper

  def survey_status(survey)
    return 'In Use' if !SurveyAssignment.published.where(survey_id: survey.id).empty?
    return '--'
  end

  def survey_question_stats(survey)
    question_groups = survey.rapidfire_question_groups
    qg_count = question_groups.count
    question_total = 0
    question_groups.collect { |qg| question_total += qg.questions.count }
    "#{qg_count} | #{question_total}"
  end
end
