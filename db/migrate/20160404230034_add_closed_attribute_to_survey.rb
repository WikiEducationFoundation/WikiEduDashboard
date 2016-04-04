class AddClosedAttributeToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :closed, :boolean, default: false
  end
end
