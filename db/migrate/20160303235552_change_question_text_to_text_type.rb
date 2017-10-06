class ChangeQuestionTextToTextType < ActiveRecord::Migration[4.2]
  def change
    change_column :rapidfire_questions, :question_text, :text
  end
end
