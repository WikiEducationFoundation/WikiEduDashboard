class AddSchoolAndTermToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :school, :string
    add_column :courses, :term, :string
  end
end
