class SurveyNotification < ActiveRecord::Base
  belongs_to :courses_user
  belongs_to :survey_assignment
  belongs_to :course
end