# frozen_string_literal: true
if @user.course_instructor?
  json.courses_count @courses_presenter.courses.count
end

if @user.course_student?
  json.individual_courses_count @individual_stats_presenter.individual_courses.count
  json.individual_word_count number_to_human @individual_stats_presenter.individual_word_count
end
