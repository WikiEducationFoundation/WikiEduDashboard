class AddCourseDataTypeToRapidfireQuestion < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :course_data_type, :string
  end
end
