class AddDetailsToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :meeting_days, :string
    add_column :courses, :signup_token, :string
    add_column :courses, :published, :bool
    add_column :courses, :approved, :bool
    add_column :courses, :assignment_source, :string
    add_column :courses, :subject, :string
    add_column :courses, :expected_students, :integer

    execute 'UPDATE courses SET approved = 1, published = 1'
  end

  def self.down
    remove_column :courses, :meeting_days
    remove_column :courses, :signup_token
    remove_column :courses, :published
    remove_column :courses, :approved
    remove_column :courses, :assignment_source
    remove_column :courses, :subject
    remove_column :courses, :expected_students
  end
end
