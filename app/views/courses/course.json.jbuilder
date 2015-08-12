json.course do
  json.(@course, :id, :title, :description, :start, :end, :school,
        :term, :subject, :slug, :url, :listed, :submitted, :listed,
        :expected_students, :timeline_start, :timeline_end, :day_exceptions,
        :weekdays)

  json.legacy @course.id < 10000
  json.ended !current?(@course) && @course.start < Time.now
  json.published CohortsCourses.exists?(course_id: @course.id)
  json.enroll_url "#{request.base_url}#{course_slug_path(@course.slug)}/enroll/"

  json.created_count number_to_human @course.new_article_count
  json.edited_count number_to_human @course.article_count
  json.edit_count number_to_human @course.revisions.count
  json.student_count @course.user_count
  json.trained_count @course.students.where(trained: true).count
  json.character_count number_to_human @course.character_sum
  json.view_count number_to_human @course.view_sum

  if user_signed_in? && current_user.role(@course) > 0
    json.passcode @course.passcode
  end
end
