class IncreaseMaxCourseDescriptionLength < ActiveRecord::Migration
  def up
    change_column :courses, :description, :text
  end

  def down
    change_column :courses, :description, :string
  end
end
