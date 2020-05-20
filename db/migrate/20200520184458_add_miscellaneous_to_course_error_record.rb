class AddMiscellaneousToCourseErrorRecord < ActiveRecord::Migration[6.0]
  def change
    add_column :course_error_records, :miscellaneous, :text
  end
end
