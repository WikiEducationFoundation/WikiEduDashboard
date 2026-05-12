# frozen_string_literal: true

class AddLmsContextTitleAndPlatformUrlToLtiCourseBindings < ActiveRecord::Migration[8.1]
  def change
    add_column :lti_course_bindings, :lms_context_title, :string
    add_column :lti_course_bindings, :lms_platform_url, :string
  end
end
