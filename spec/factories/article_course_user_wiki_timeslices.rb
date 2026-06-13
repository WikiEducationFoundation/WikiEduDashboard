# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_user_wiki_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  wiki_id          :integer          not null
#  article_id       :integer          not null
#  user_id          :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  first_revision   :datetime
#  stats            :text
#  needs_update     :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :article_course_user_wiki_timeslice, class: 'ArticleCourseUserWikiTimeslice' do
    nil
  end
end
