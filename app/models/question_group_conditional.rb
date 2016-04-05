class QuestionGroupConditional < ActiveRecord::Base
  belongs_to :rapidfire_question_group, class_name: 'Rapidfire::QuestionGroup'
  belongs_to :cohort
end
