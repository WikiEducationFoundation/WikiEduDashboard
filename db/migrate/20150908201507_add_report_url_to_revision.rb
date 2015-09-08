class AddReportUrlToRevision < ActiveRecord::Migration
  def change
    add_column :revisions, :report_url, :string, default: nil
  end
end
