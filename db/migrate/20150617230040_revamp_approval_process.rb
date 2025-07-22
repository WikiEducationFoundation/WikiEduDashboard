class RevampApprovalProcess < ActiveRecord::Migration[4.2]
  def change
    remove_column :courses, :approved
    remove_column :courses, :published
  end
end
