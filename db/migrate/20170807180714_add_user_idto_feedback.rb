class AddUserIdtoFeedback < ActiveRecord::Migration[5.1]
  def change
  	add_column :feedbacks, :user_id, :integer, references: :users
  end
end
