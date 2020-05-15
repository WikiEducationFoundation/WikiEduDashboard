class AddAssociationKeyToCourseErrorRecord < ActiveRecord::Migration[6.0]
  def change
    add_column :course_error_records, :course_id, :integer
  end
end
