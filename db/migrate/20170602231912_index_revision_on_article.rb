class IndexRevisionOnArticle < ActiveRecord::Migration[5.1]
  def change
    add_index :revisions, :article_id
  end
end
