class AddTimeZoneToCourse < ActiveRecord::Migration[5.0]
  def up
    add_column :courses, :time_zone, :string, default: 'UTC'
  end

  def down
    remove_column :courses, :time_zone
  end
end
