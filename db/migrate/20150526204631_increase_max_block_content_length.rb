class IncreaseMaxBlockContentLength < ActiveRecord::Migration
  def up
    change_column :blocks, :content, :string, limit: 5000
  end

  def down
    change_column :blocks, :content, :string, limit: 255
  end
end
