class AddClonedStatusToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :cloned_status, :integer
  end
end
