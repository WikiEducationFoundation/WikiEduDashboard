class AddCourseIdToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :course_id, :integer, null:false
  end
end
