class AddSubmittedToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :submitted, :integer, default: false
  end
end
