# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id               :bigint           not null, primary key
#  start            :datetime
#  end              :datetime
#  last_mw_rev_id   :integer
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  user_ids         :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  article_id       :integer          not null
#  course_id        :integer          not null
#  new_article      :boolean          default(FALSE)
#

FactoryBot.define do
  factory :article_course_timeslice, class: 'ArticleCourseTimeslice' do
    nil
  end
end
