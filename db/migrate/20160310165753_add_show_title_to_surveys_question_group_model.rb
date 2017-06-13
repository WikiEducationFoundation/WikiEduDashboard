class AddShowTitleToSurveysQuestionGroupModel < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys_question_groups, :show_title, :boolean, :default => false
  end
end
