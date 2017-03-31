class AddSlugIndexToCourses < ActiveRecord::Migration[4.2]
  def change
    add_index :courses, :slug
  end
end
