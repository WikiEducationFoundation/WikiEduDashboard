class ConvertTrainingModulesToUtf8Mb4 < ActiveRecord::Migration[6.0]
  def change
    execute "ALTER TABLE training_slides CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE training_slides MODIFY content TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE training_slides MODIFY translations TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  end
end
