class FixUniqueAssignmentCaseSensitivity < ActiveRecord::Migration[5.0]
  def change
    remove_index :assignments, :name => 'by_course_user_article_and_role'
  end
end
