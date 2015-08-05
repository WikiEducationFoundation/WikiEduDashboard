# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  kind         :integer
#  content      :string(5000)
#  week_id      :integer
#  gradeable_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#  title        :string(255)
#  order        :integer
#  duration     :integer          default(1)
#

FactoryGirl.define do
  factory :block do
    kind 1
    content 'MyString'
    order 0
  end
end
