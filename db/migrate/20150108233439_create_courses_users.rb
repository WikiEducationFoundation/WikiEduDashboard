class CreateCoursesUsers < ActiveRecord::Migration
  def change
    create_table :courses_users do |t|

      t.timestamps
    end
  end
end
