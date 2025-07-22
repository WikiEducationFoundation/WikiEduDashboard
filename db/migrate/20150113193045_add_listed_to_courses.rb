class AddListedToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :listed, :boolean
  end
end
