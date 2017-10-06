class AddReportUrlToRevision < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :report_url, :string, default: nil
  end
end
