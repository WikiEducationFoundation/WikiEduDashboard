# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  article_id       :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  user_ids         :text(65535)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  first_revision   :datetime
#

FactoryBot.define do
  factory :article_course_timeslice, class: 'ArticleCourseTimeslice' do
    nil
  end
end
