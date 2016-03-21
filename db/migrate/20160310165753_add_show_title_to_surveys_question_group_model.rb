class AddShowTitleToSurveysQuestionGroupModel < ActiveRecord::Migration
  def change
    add_column :surveys_question_groups, :show_title, :boolean, :default => false
  end
end
