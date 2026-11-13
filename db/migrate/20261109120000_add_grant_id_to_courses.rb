# frozen_string_literal: true

# The grant that funds a program, as listed in the grant ID spreadsheet
# (see GrantIdList). Set from the course Details panel.
class AddGrantIdToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :grant_id, :string
  end
end
