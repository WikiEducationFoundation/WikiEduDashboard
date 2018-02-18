class AddWithdrawnToCourse < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :withdrawn, :boolean, default: false
  end
end
