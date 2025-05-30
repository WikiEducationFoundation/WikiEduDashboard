# frozen_string_literal: true
# == Schema Information
#
# Table name: course_user_wiki_timeslices
#
#  id                  :bigint           not null, primary key
#  course_id           :integer          not null
#  user_id             :integer          not null
#  wiki_id             :integer          not null
#  start               :datetime
#  end                 :datetime
#  character_sum_ms    :integer          default(0)
#  character_sum_us    :integer          default(0)
#  character_sum_draft :integer          default(0)
#  references_count    :integer          default(0)
#  revision_count      :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :course_user_wiki_timeslice, class: 'CourseUserWikiTimeslice' do
    nil
  end
end
