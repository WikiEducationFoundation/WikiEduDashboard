class AddNeedsUpdateToCourse < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :needs_update, :boolean, default: false
  end
end
