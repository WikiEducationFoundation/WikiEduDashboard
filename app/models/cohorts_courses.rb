#= Cohort + Course join model
class CohortsCourses < ActiveRecord::Base
  belongs_to :cohort
  belongs_to :course
end
