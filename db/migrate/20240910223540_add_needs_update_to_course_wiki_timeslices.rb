class AddNeedsUpdateToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :needs_update, :boolean, :default => false
  end
end
