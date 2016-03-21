class AddIntroAndThanksToSurveyModel < ActiveRecord::Migration
  def change
    remove_column :rapidfire_question_groups, :intro_slide, :text
    remove_column :rapidfire_question_groups, :final_slide, :text
    add_column :surveys, :intro, :text
    add_column :surveys, :thanks, :text
  end
end
