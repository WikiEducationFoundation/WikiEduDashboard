class RemoveShowTitleFromSurveysQuestionGroups < ActiveRecord::Migration[4.2]
  def change
    remove_column :surveys_question_groups, :show_title
  end
end
