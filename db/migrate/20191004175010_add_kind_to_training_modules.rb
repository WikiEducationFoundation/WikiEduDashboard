class AddKindToTrainingModules < ActiveRecord::Migration[6.0]
  def change
    add_column :training_modules, :kind, :integer, default: 0, limit: 1
  end
end
