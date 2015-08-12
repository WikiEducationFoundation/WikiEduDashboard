# == Schema Information
#
# Table name: cohorts_courses
#
#  id         :integer          not null, primary key
#  cohort_id  :integer
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

#= Cohort + Course join model
class CohortsCourses < ActiveRecord::Base
  belongs_to :cohort
  belongs_to :course
end
