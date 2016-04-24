class RemoveReportUrlFromRevision < ActiveRecord::Migration
  def up
    remove_column :revisions, :report_url
  end

  def down
    add_column :revisions, :report_url, :string, default: nil
  end
end
