class AddWikiTokenAndSecretToUser < ActiveRecord::Migration
  def change
    add_column :users, :wiki_token, :string
    add_column :users, :wiki_secret, :string
  end
end
