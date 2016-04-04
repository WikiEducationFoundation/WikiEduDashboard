class AddOpenAttributeToSurveyModel < ActiveRecord::Migration
  def change
    add_column :surveys, :open, :boolean, default: false
  end
end
