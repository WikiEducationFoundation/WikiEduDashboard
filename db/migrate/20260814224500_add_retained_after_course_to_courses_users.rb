# frozen_string_literal: true

class AddRetainedAfterCourseToCoursesUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :courses_users, :retained_after_course, :boolean, default: nil
    add_column :courses_users, :retained_after_course_checked_at, :datetime, default: nil
  end
end
