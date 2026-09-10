# frozen_string_literal: true

class AddRetainedEditorsToSystemAndFacilitatorStats < ActiveRecord::Migration[7.0]
  def change
    add_column :system_stats, :retained_new_editors_count, :integer, default: 0
    add_column :facilitator_stats, :retained_new_editors_count, :integer, default: 0
  end
end
