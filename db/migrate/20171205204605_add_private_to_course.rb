class AddPrivateToCourse < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :private, :boolean, default: false
  end
end
