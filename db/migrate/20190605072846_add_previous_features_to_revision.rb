class AddPreviousFeaturesToRevision < ActiveRecord::Migration[5.2]
  def change
    add_column :revisions, :features_previous, :text
  end
end
