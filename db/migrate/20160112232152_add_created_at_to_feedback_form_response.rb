class AddCreatedAtToFeedbackFormResponse < ActiveRecord::Migration[4.2]
  def change
    add_column :feedback_form_responses, :created_at, :datetime
  end
end
