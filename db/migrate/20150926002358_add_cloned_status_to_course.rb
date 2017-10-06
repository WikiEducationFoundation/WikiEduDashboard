class AddClonedStatusToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :cloned_status, :integer
  end
end
