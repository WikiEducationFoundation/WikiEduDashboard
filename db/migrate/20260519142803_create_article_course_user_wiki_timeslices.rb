# frozen_string_literal: true

class CreateArticleCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :article_course_user_wiki_timeslices do |t|
      t.integer :course_id, null: false
      t.integer :wiki_id, null: false
      t.integer :article_id, null: false
      t.integer :user_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :character_sum, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0
      t.boolean :new_article, default: false
      t.boolean :tracked, default: true
      t.datetime :first_revision

      t.timestamps
    end
  end
end
