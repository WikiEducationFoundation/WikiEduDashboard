class AddSubjectIdToAlert < ActiveRecord::Migration[5.0]
  def change
    add_column :alerts, :subject_id, :integer
  end
end
