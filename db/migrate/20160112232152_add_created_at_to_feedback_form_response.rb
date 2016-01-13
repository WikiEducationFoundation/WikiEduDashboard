class AddCreatedAtToFeedbackFormResponse < ActiveRecord::Migration
  def change
    add_column :feedback_form_responses, :created_at, :datetime
  end
end
