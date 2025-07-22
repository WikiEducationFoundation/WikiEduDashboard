class AddCharacterSumDraftToCoursesUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :courses_users, :character_sum_draft, :integer, default: 0
  end
end
