class IncreaseMaxCourseDescriptionLength < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :description, :text
  end

  def down
    change_column :courses, :description, :string
  end
end
