class AddAlertConditionsToRapidfireQuestion < ActiveRecord::Migration[5.0]
  def change
    add_column :rapidfire_questions, :alert_conditions, :text
  end
end
