class CreateCourseErrorRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :course_error_records do |t|
      t.string :type_of_error
      t.text :api_call_url

      t.timestamps
    end
  end
end
