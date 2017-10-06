class AddConfidentialResultsToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :confidential_results, :boolean, default: false
  end
end
