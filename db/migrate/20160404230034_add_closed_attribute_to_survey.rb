class AddClosedAttributeToSurvey < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :closed, :boolean, default: false
  end
end
