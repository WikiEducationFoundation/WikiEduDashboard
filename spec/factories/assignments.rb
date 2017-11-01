# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#  course_id     :integer
#  article_id    :integer
#  article_title :string(255)
#  role          :integer
#  wiki_id       :integer
#

FactoryBot.define do
  # article that exists
  factory :assignment do
    created_at '2015-02-18 18:02:50'
    updated_at '2015-02-18 18:03:01'
    user_id 236_820_32
    course_id 481
    article_id 124_884_99
    article_title 'Siderocalin'
    wiki_id 1
  end

  # article that does not exist
  factory :redlink, class: Assignment do
    created_at '2015-02-18 18:02:50'
    updated_at '2015-02-18 18:02:50'
    user_id 224_977_86
    course_id 481
    article_id nil
    article_title 'Faecal calprotectin'
  end
end
