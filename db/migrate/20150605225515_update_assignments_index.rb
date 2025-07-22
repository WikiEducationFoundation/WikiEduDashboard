class UpdateAssignmentsIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :assignments, :name => 'by_course_user_and_article'
    add_index :assignments, [:course_id, :user_id, :article_title, :role], :unique => true, :name => 'by_course_user_article_and_role'
  end
end
