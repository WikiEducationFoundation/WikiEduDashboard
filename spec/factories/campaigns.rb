# frozen_string_literal: true
# == Schema Information
#
# Table name: campaigns
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  slug       :string(255)
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :campaign do
    title 'Spring 2016'
    slug 'spring_2016'
  end

  factory :campaign_two, class: Campaign do
    title 'Fall 2014'
    slug 'fall_2014'
    url 'Wikipedia:Education_program/Dashboard/Fall_2014_course_ids'
  end
end
