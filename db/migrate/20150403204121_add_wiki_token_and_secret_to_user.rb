class AddWikiTokenAndSecretToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :wiki_token, :string
    add_column :users, :wiki_secret, :string
  end
end
