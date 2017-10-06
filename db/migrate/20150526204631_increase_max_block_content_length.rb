class IncreaseMaxBlockContentLength < ActiveRecord::Migration[4.2]
  def up
    change_column :blocks, :content, :string, limit: 5000
  end

  def down
    change_column :blocks, :content, :string, limit: 255
  end
end
