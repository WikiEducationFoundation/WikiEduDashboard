class AddOptoutToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :optout, :text
  end
end
