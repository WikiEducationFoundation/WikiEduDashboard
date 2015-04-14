class AddDetailsToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :meeting_days, :string
    add_column :courses, :signup_token, :string
    add_column :courses, :published, :bool
    add_column :courses, :approved, :bool
    add_column :courses, :assignment_source, :string
    add_column :courses, :subject, :string
    add_column :courses, :expected_students, :integer
  end
end
