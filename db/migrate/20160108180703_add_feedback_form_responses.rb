class AddFeedbackFormResponses < ActiveRecord::Migration[4.2]
  def change
    create_table :feedback_form_responses do |t|
      t.string :subject
      t.text :body
      t.integer :user_id
    end
  end
end
