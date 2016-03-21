class AddPositionToSurveysQuestionGroups < ActiveRecord::Migration
  def change
    add_column :surveys_question_groups, :id, :primary_key
    add_column :surveys_question_groups, :position, :integer
    add_column :surveys_question_groups, :created_at, :datetime
    add_column :surveys_question_groups, :updated_at, :datetime
  end
end
