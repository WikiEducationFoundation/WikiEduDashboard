class AddLevelToCourse < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :level, :string
  end
end
