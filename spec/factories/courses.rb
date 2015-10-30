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
#  untrained_count   :integer          default(0)
#  meeting_days      :string(255)
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(255)      default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#

FactoryGirl.define do
  factory :course do
    start Date.new(2015, 01, 01)
    # end is a reserved keyword, set that in the let(:course) calls
    title 'Underwater basket-weaving'
    listed true
    school 'WINTR'
    term 'spring 2015'
    slug 'WINTR/Underwater_basket-weaving_(spring_2015)'
    passcode 'pizza'
  end
end
