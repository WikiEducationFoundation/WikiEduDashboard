class AddFlagsToCourse < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :flags, :text
  end
end
