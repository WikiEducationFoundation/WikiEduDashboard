class AddCourseIdToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :article_course_timeslices, :course_id, :integer, null: false
  end
end
