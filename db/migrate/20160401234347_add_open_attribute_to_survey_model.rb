class AddOpenAttributeToSurveyModel < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :open, :boolean, default: false
  end
end
