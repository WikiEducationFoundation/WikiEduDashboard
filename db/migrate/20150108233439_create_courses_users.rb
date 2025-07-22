class CreateCoursesUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :courses_users do |t|

      t.timestamps
    end
  end
end
