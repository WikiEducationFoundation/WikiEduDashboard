class ChangeMwRevIdSize < ActiveRecord::Migration[7.0]
  def up
    change_column :revisions, :mw_rev_id, :bigint
  end
end
