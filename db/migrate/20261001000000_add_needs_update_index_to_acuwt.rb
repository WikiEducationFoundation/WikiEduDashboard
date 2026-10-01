# frozen_string_literal: true

class AddNeedsUpdateIndexToAcuwt < ActiveRecord::Migration[8.1]
  def change
    add_index :article_course_user_wiki_timeslices, %i[needs_update course_id],
              name: 'index_acuwt_on_needs_update_and_course_id'
  end
end
