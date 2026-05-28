class AddMwRevCountToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :mw_rev_count, :integer, default: 0
  end
end
