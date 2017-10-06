class AddIntroAndThanksToSurveyModel < ActiveRecord::Migration[4.2]
  def change
    remove_column :rapidfire_question_groups, :intro_slide, :text
    remove_column :rapidfire_question_groups, :final_slide, :text
    add_column :surveys, :intro, :text
    add_column :surveys, :thanks, :text
  end
end
