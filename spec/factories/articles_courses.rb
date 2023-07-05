# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id               :integer          not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  article_id       :integer
#  course_id        :integer
#  view_count       :bigint           default(0)
#  character_sum    :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  references_count :integer          default(0)
#  tracked          :boolean          default(TRUE)
#  user_ids         :text(65535)
#

FactoryBot.define do
  factory :articles_course, class: 'ArticlesCourses' do
    nil
  end
end
