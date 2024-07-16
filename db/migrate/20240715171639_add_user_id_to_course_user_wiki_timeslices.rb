class AddUserIdToCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_user_wiki_timeslices, :user_id, :integer, null: false
  end
end
