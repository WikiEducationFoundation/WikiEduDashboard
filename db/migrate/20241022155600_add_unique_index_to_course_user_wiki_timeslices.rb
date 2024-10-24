class AddUniqueIndexToCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :course_user_wiki_timeslices, [:course_id, :user_id, :wiki_id, :start, :end], unique: true, name: 'course_user_wiki_timeslice_by_course_user_wiki_start_and_end'
  end
end
