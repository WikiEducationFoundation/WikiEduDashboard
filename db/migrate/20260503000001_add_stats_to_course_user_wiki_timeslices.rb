# frozen_string_literal: true

class AddStatsToCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_user_wiki_timeslices, :stats, :text
  end
end
