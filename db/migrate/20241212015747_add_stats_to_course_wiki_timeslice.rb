class AddStatsToCourseWikiTimeslice < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :stats, :text
  end
end
