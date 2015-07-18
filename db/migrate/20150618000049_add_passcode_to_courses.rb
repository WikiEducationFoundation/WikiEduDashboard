class AddPasscodeToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :passcode, :string
  end
end
