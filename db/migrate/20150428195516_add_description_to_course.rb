class AddDescriptionToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :description, :string
  end
end
