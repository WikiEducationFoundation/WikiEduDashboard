class Survey < ActiveRecord::Base
  has_many :rapidfire_question_groups
end
