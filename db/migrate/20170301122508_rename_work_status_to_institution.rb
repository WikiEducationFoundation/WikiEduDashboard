class RenameWorkStatusToInstitution < ActiveRecord::Migration[5.0]
  def change
    rename_column :user_profiles, :work_status, :institution
  end
end
