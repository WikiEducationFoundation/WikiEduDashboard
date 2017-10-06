class RemoveReportUrlFromRevision < ActiveRecord::Migration[4.2]
  def up
    remove_column :revisions, :report_url
  end

  def down
    add_column :revisions, :report_url, :string, default: nil
  end
end
