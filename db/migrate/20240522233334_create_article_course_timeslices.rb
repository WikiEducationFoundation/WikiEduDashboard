class CreateArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :article_course_timeslices do |t|
      t.integer :course_id, null: false
      t.integer :article_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :character_sum, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0
      t.text :user_ids
      t.boolean :new_article, default: false
      t.boolean :tracked, default: true

      t.timestamps
    end

    add_index :article_course_timeslices,
              [:article_id, :course_id, :start, :end],
              unique: true,
              name: 'article_course_timeslice_by_article_course_start_and_end'

    add_index :article_course_timeslices,
              [:course_id, :updated_at, :article_id],
              name: 'article_course_timeslice_by_updated_at'

    add_index :article_course_timeslices,
              [:course_id, :tracked],
              name: 'article_course_timeslice_by_tracked'
  end
end
