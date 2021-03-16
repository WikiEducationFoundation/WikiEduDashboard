class AddUniqueArticleIndex < ActiveRecord::Migration[6.0]
  def change
    change_table :articles do |t|
      t.index :index_hash, unique: true
    end
  end
end
