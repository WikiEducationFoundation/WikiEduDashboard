class AddChatIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :chat_id, :string
  end
end
