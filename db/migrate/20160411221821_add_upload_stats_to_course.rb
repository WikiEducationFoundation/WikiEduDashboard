class AddUploadStatsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :upload_count, :integer, default: 0
    add_column :courses, :uploads_in_use_count, :integer, default: 0
    add_column :courses, :upload_usages_count, :integer, default: 0
  end
end
