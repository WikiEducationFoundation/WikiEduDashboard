class ChangeQuestionTextToTextType < ActiveRecord::Migration
  def change
    change_column :rapidfire_questions, :question_text, :text
  end
end
