class AddCohortToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :cohort, :string
  end
end
