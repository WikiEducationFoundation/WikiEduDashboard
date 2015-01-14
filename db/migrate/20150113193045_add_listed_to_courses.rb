class AddListedToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :listed, :boolean
  end
end
