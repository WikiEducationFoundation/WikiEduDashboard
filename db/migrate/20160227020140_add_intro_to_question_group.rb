class AddIntroToQuestionGroup < ActiveRecord::Migration
  def change
    add_column :rapidfire_question_groups, :intro_slide, :string
    add_column :rapidfire_question_groups, :final_slide, :string
  end
end
