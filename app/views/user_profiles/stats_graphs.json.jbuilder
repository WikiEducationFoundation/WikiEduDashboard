# frozen_string_literal: true
if @user.course_instructor?
  json.instructor_stats do
    i = 0
    json.array! @courses_presenter.courses.each do |course|
      i += 1
      json.index i
      json.course_id course.id
      json.course_title course.title
      json.course_start course.start
      json.course_end course.end
      json.articles_edited course.article_count
      json.articles_created course.new_article_count
      json.by_students_common_uploads course.upload_count
    end
  end


  json.student_count do
    i = 0
    json.array! CoursesUsers.where(course: @courses_presenter.courses, role: 0).each do |course_user|
      i += 1
      json.index i
      json.created_at = course_user.created_at
    end
  end

  json.revisions do
    i = 0
    result = []
    json.array! @courses_presenter.courses.each do |course|
      result += json.array! course.revisions.each do |revision|
        i += 1
        json.index i
        json.date revision.date
        json.characters revision.characters
        json.views_count revision.views
      end
    end
  end
end

# if @user.course_student?
#   json.as_student_stats do
#   end
# end
