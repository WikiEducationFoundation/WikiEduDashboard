class AddFeaturesToRevision < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :features, :text
  end
end
