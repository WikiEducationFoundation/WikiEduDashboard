class IncreaseLimitOfCommonsUploadFileName < ActiveRecord::Migration[5.0]
  def up
    change_column :commons_uploads, :file_name, :string, limit: 2000
  end

  def down
    change_column :commons_uploads, :file_name, :string, limit: 255
  end
end
