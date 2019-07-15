class AddSandboxUrlToAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :assignments, :sandbox_url, :text
  end
end
