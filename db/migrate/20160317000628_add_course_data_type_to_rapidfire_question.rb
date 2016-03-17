class AddCourseDataTypeToRapidfireQuestion < ActiveRecord::Migration
  def change
    add_column :rapidfire_questions, :course_data_type, :string
  end
end
