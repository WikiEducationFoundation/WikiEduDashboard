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

FactoryGirl.define do
  factory :cohorts_course, class: 'CohortsCourses' do
  end
end
