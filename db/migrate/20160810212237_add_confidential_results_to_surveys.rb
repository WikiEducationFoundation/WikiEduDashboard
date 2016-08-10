class AddConfidentialResultsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :confidential_results, :boolean, default: false
  end
end
