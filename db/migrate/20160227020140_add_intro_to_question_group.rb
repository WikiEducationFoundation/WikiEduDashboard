class AddIntroToQuestionGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_question_groups, :intro_slide, :text
    add_column :rapidfire_question_groups, :final_slide, :text
  end
end
