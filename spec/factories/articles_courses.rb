# frozen_string_literal: true

# == Schema Information
#
# Table name: articles_courses
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  article_id    :integer
#  course_id     :integer
#  view_count    :integer          default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

FactoryBot.define do
  factory :articles_course, class: 'ArticlesCourses' do
    nil
  end
end
