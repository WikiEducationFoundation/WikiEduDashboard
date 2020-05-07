class ConvertTrainingModulesToUtf8Mb4 < ActiveRecord::Migration[6.0]
  def change
    remove_index :training_slides, :slug
    execute "ALTER TABLE training_slides ROW_FORMAT=DYNAMIC"
    execute "ALTER TABLE training_slides CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE training_slides MODIFY content TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    # This has been run on dashboard.wikiedu.org production but errors on outreachdashboard.wmflabs.org where
    # the translations are actually used.
    # execute "ALTER TABLE training_slides MODIFY translations TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    add_index :training_slides, :slug, unique: true, length: 191
  end
end
