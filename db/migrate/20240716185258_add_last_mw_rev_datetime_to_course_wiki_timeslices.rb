class AddLastMwRevDatetimeToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :last_mw_rev_datetime, :datetime
  end
end
