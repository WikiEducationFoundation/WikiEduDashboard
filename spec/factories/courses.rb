# frozen_string_literal: true
# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  title             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  start             :date
#  end               :date
#  school            :string(255)
#  term              :string(255)
#  character_sum     :integer          default(0)
#  view_sum          :integer          default(0)
#  user_count        :integer          default(0)
#  article_count     :integer          default(0)
#  revision_count    :integer          default(0)
#  slug              :string(255)
#  listed            :boolean          default(TRUE)
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text(65535)
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(2000)     default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#  no_day_exceptions :boolean          default(FALSE)
#  trained_count     :integer          default(0)
#  cloned_status     :integer
#  type              :string(255)      default("ClassroomProgramCourse")
#

FactoryGirl.define do
  factory :course, class: 'ClassroomProgramCourse' do
    start Date.new(2015, 0o1, 0o1)
    self.end Date.new(2015, 0o6, 0o1)
    title 'Underwater basket-weaving'
    listed true
    school 'WINTR'
    term 'spring 2015'
    slug 'WINTR/Underwater_basket-weaving_(spring_2015)'
    passcode 'pizza'
    home_wiki_id 1
  end

  factory :basic_course, class: 'BasicCourse' do
    start Date.new(2015, 0o1, 0o1)
    self.end Date.new(2015, 0o6, 0o1)
    title 'Black life matters'
    listed true
    school 'none'
    term 'none'
    slug 'Black_life_matters'
    type 'BasicCourse'
    passcode 'pizzå'
    home_wiki_id 1
  end

  factory :visiting_scholarship, class: 'VisitingScholarship' do
    start Date.new(2015, 0o1, 0o1)
    self.end Date.new(2015, 0o6, 0o1)
    title 'Basket-weaving scholarship'
    listed true
    school 'UNR'
    term 'spring 2015'
    slug 'UNR/Basket-weaving_scholarship_(spring_2015)'
    passcode 'pizza'
    type 'VisitingScholarship'
    home_wiki_id 1
  end

  factory :editathon, class: 'Editathon' do
    start Date.new(2015, 0o1, 0o1)
    self.end Date.new(2015, 0o6, 0o1)
    title 'Basket-weaving edit-a-thon'
    listed true
    school 'NARA'
    term 'spring 2015'
    slug 'NARA/Basket-weaving_edit-a-thon_(spring_2015)'
    passcode 'pizza'
    type 'Editathon'
    home_wiki_id 1
  end

  factory :legacy_course, class: 'LegacyCourse' do
    start Date.new(2013, 0o1, 0o1)
    self.end Date.new(2013, 0o6, 0o1)
    title 'Legacy basket-weaving'
    listed true
    school 'PBR'
    term 'spring 2013'
    slug 'PRB/Legacy_basket-weaving_edit-a-thon_(spring_2013)'
    passcode 'pizza'
    type 'LegacyCourse'
    home_wiki_id 1
  end
end
