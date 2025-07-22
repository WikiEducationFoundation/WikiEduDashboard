class AddSourceToCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :categories, :source, :string, default: 'category'
  end
end
