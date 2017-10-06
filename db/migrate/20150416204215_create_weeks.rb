class CreateWeeks < ActiveRecord::Migration[4.2]
  def change
    create_table :weeks do |t|
      t.string :title
      t.date :start

      t.integer :course_id

      t.timestamps
    end
  end
end
