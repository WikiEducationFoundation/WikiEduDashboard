class AddPasscodeToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :passcode, :string
  end
end
