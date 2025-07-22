class ChangeDataTypeForBlock < ActiveRecord::Migration[4.2]
  def up
    change_column :blocks, :content, :text
  end

  def down
    change_column :blocks, :content, :string, limit: 5000
  end
end
