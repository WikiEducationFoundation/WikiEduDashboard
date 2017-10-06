class AddUniqueConstraintToCourseSlug < ActiveRecord::Migration[5.0]
  def change
    remove_index :courses, :slug
    add_index :courses, :slug, unique: true
  end
end
