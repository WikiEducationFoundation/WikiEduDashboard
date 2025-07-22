class AddSummaryToRevision < ActiveRecord::Migration[6.0]
  def change
    add_column :revisions, :summary, :text
  end
end
