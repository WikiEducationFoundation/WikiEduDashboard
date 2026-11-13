# frozen_string_literal: true

# The grant IDs that courses may be linked to, copied from the grant ID
# spreadsheet each week by RefreshGrantIdsWorker.
class CreateValidGrantIds < ActiveRecord::Migration[8.1]
  def change
    create_table :valid_grant_ids do |t|
      t.string :grant_id, null: false
      t.timestamps
    end
    add_index :valid_grant_ids, :grant_id, unique: true
  end
end
