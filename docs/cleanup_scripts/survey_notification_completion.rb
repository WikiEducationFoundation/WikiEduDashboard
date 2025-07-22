# Repair SurveyNotification records that didn't get updated upon survey completion
# because of a CSRF error between July and September 2022
SurveyAssignment.all.each do |sa|
  sa = SurveyAssignment.last
  survey = sa.survey
  question_group_ids = survey.rapidfire_question_group_ids
  sa.survey_notifications.where(completed: false).includes(courses_user: :user).each do |sn|
    next unless Rapidfire::AnswerGroup.exists?(question_group_id: question_group_ids, course_id: sn.course_id, user_id: sn.user.id)
    puts sn.id
    sn.update(completed: true, dismissed: true)
  end
end

