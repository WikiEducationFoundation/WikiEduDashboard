class RemoveCourseUserIdFromCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    remove_column :course_user_wiki_timeslices, :course_user_id, :integer
  end
end
