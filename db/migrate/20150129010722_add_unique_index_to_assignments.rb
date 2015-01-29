class AddUniqueIndexToAssignments < ActiveRecord::Migration
  def change
    add_index :assignments, [ :course_id, :user_id, :article_title], :unique => true, :name => 'by_course_user_and_article'
  end
end
