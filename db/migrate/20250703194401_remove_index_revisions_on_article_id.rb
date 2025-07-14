class RemoveIndexRevisionsOnArticleId < ActiveRecord::Migration[7.0]
  def change
    remove_index :revisions, name: "index_revisions_on_article_id"
  end
end
