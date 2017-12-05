# frozen_string_literal: true

# == Schema Information
#
# Table name: revisions
#
#  id             :integer          not null, primary key
#  characters     :integer          default(0)
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  article_id     :integer
#  views          :integer          default(0)
#  date           :datetime
#  new_article    :boolean          default(FALSE)
#  deleted        :boolean          default(FALSE)
#  wp10           :float(24)
#  wp10_previous  :float(24)
#  system         :boolean          default(FALSE)
#  ithenticate_id :integer
#  wiki_id        :integer
#  mw_rev_id      :integer
#  mw_page_id     :integer
#  features       :text(65535)
#

FactoryBot.define do
  factory :revision do
    date '2014-12-17'
    characters 1
    wiki_id 1
    sequence(:mw_rev_id)
    sequence(:mw_page_id)
  end
end
