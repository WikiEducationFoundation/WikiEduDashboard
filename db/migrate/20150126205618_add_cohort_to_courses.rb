class AddCohortToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :cohort, :string
  end
end
