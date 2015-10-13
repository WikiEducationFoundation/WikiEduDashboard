# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  kind         :integer
#  content      :text
#  week_id      :integer
#  gradeable_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#  title        :string(255)
#  order        :integer
#  due_date     :datetime
#

FactoryGirl.define do
  factory :block do
    kind Block::KINDS['assignment']
    content 'MyString'
    order 0
  end
end
