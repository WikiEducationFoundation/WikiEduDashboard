class AddFeaturesToRevision < ActiveRecord::Migration
  def change
    add_column :revisions, :features, :text
  end
end
