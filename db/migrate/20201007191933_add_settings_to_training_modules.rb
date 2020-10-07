class AddSettingsToTrainingModules < ActiveRecord::Migration[6.0]
  def change
    add_column :training_modules, :settings, :text
  end
end
