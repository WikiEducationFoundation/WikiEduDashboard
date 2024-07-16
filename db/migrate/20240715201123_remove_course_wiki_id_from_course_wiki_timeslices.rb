class RemoveCourseWikiIdFromCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    remove_column :course_wiki_timeslices, :course_wiki_id, :integer
  end
end
