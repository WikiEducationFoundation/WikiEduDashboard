class AddOptoutToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :optout, :text
  end
end
