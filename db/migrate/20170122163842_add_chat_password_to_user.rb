class AddChatPasswordToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :chat_password, :string
  end
end
