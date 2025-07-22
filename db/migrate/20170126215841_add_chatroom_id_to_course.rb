class AddChatroomIdToCourse < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :chatroom_id, :string
  end
end
