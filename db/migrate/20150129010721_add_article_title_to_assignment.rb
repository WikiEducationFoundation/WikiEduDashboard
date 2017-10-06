class AddArticleTitleToAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :article_title, :string
  end
end
