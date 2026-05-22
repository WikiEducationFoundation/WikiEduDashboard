# frozen_string_literal: true

class AddStatsToArticleCourseUserWikiTimeslices < ActiveRecord::Migration[7.1]
  def change
    add_column :article_course_user_wiki_timeslices, :stats, :text
  end
end
