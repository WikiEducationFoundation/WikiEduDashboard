# frozen_string_literal: true

class AddNeedsUpdateToArticleCourseUserWikiTimeslices < ActiveRecord::Migration[7.1]
  def change
    add_column :article_course_user_wiki_timeslices, :needs_update, :boolean, default: false
  end
end
