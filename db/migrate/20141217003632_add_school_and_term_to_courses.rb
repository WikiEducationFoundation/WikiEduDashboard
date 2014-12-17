class AddSchoolAndTermToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :school, :string
    add_column :courses, :term, :string
  end
end
