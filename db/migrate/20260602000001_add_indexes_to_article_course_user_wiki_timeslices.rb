# frozen_string_literal: true

class AddIndexesToArticleCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :article_course_user_wiki_timeslices,
              %i[course_id article_id user_id wiki_id start end],
              unique: true,
              name: 'index_acuwt_unique'
    add_index :article_course_user_wiki_timeslices, %i[course_id wiki_id],
              name: 'index_acuwt_on_course_id_and_wiki_id'
    add_index :article_course_user_wiki_timeslices, %i[course_id user_id],
              name: 'index_acuwt_on_course_id_and_user_id'
  end
end
