class CreateCourseStats < ActiveRecord::Migration[6.1]
  def change
    create_table :course_stats do |t|
      t.text :stats_hash
      t.references :course, type: :integer, foreign_key: true

      t.timestamps
    end
  end
end
