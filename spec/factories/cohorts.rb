# == Schema Information
#
# Table name: cohorts
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  slug       :string(255)
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :cohort do
    title 'Spring 2015'
    slug 'spring_2015'
    url 'Wikipedia:Education_program/Dashboard/course_ids'
  end

  factory :cohort_two, class: Cohort do
    title 'Fall 2014'
    slug 'fall_2014'
    url 'Wikipedia:Education_program/Dashboard/Fall_2014_course_ids'
  end
end
