# frozen_string_literal: true

class AddUpdatedAtIndexToArticleCourseUserWikiTimeslices < ActiveRecord::Migration[8.1]
  def change
    add_index :article_course_user_wiki_timeslices, %i[course_id updated_at article_id], name: 'index_acuwt_on_course_id_updated_at_and_article_id'
  end
end
