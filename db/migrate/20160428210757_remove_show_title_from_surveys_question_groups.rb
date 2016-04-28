class RemoveShowTitleFromSurveysQuestionGroups < ActiveRecord::Migration
  def change
    remove_column :surveys_question_groups, :show_title
  end
end
