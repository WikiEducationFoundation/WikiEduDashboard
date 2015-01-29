class AddArticleTitleToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :article_title, :string
  end
end
