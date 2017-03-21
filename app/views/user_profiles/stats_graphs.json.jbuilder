# frozen_string_literal: true
if @user.course_instructor?
  json.asinstructor_stats do
    json.courses_count do
      i = 0
      json.array! @courses_presenter.courses.each do |course|
        i += 1
        json.index i
        json.course_id course.id
        json.course_title course.title
        json.course_start course.start
        json.course_end course.end
      end
    end

    json.students_count do
      i = 0
      result = []
      @courses_presenter.courses.each do |course|
        result += json.array! course.courses_users.where('courses_users.role = ?', CoursesUsers::Roles::STUDENT_ROLE).each do |course_user|
          i += 1
          json.index i
          json.created_at = course_user.created_at
        end
      end
    end
  end

  json.bystudents_stats do
    json.word_count do
      i = 0
      result = []
      @courses_presenter.courses.each do |course|
        result += json.array! course.revisions.each do |revision|
          i += 1
          json.index i
          json.date revision.date
          json.characters revision.characters
        end
      end
    end
  end
end
