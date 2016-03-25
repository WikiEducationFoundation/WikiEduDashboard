class SurveyAssignment < ActiveRecord::Base
  belongs_to :survey
  has_and_belongs_to_many :cohorts
  # validate :maximum_surveys_length
  # validate :maximum_cohorts_length

  # def maximum_surveys_length
  #   if self.surveys.length > 1
  #     self.errors.add(:surveys, "Cannot assign to more than 1 Survey")
  #   end
  # end

  def maximum_cohorts_length
    # if self.cohorts.length > 1
    #   self.errors.add(:cohorts, "Cannot assign to more than 1 Cohort")
    # end
  end
end
