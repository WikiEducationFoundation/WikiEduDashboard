class AddSlugToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :slug, :string
  end
end
