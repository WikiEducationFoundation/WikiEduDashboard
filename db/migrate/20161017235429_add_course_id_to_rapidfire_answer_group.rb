class AddCourseIdToRapidfireAnswerGroup < ActiveRecord::Migration[5.0]
  def change
    add_column :rapidfire_answer_groups, :course_id, :integer
  end
end
