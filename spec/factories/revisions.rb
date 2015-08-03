# == Schema Information
#
# Table name: revisions
#
#  id          :integer          not null, primary key
#  characters  :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#  user_id     :integer
#  article_id  :integer
#  views       :integer          default(0)
#  date        :datetime
#  new_article :boolean          default(FALSE)
#  deleted     :boolean          default(FALSE)
#  system      :boolean          default(FALSE)
#

FactoryGirl.define do
  factory :revision do
    date '2014-12-17'
    characters 1
  end
end
