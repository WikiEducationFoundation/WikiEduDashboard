class Survey < ActiveRecord::Base
  has_many :survey_assignments, dependent: :destroy
  has_and_belongs_to_many :rapidfire_question_groups, class_name: "Rapidfire::QuestionGroup",
    join_table: "surveys_question_groups", association_foreign_key: "rapidfire_question_group_id"
  accepts_nested_attributes_for :rapidfire_question_groups
end
