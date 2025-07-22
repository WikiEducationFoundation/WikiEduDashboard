# This migration comes from ticket_dispenser (originally 20190410173213)
class AddDetailsToMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :ticket_dispenser_messages, :details, :text
  end
end
