class AddUniqueIndexToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_index :assignments, [ :course_id, :user_id, :article_title], :unique => true, :name => 'by_course_user_and_article'
  end
end
