class AddSubmittedToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :submitted, :integer, default: false
  end
end
