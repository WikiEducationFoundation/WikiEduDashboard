class AddFollowUpQuestionFields < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :follow_up_question_text, :text
    add_column :rapidfire_answers, :follow_up_answer_text, :text
  end
end
