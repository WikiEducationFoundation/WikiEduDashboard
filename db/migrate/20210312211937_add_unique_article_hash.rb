class AddUniqueArticleHash < ActiveRecord::Migration[6.0]
  def change
    change_table :articles do |t|
      t.virtual :index_hash, type: :string, as: "IF(deleted, NULL, CONCAT(mw_page_id, '-', wiki_id))", stored: true
    end
  end
end
