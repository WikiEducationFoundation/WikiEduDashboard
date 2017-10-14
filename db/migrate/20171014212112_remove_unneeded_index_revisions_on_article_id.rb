class RemoveUnneededIndexRevisionsOnArticleId < ActiveRecord::Migration[5.1]
  def change
    remove_index :revisions, name: :index_revisions_on_article_id
  end
end
