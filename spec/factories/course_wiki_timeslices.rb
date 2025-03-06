# frozen_string_literal: true

# == Schema Information
#
# Table name: course_wiki_timeslices
#
#  id                   :bigint           not null, primary key
#  course_id            :integer          not null
#  wiki_id              :integer          not null
#  start                :datetime
#  end                  :datetime
#  character_sum        :integer          default(0)
#  references_count     :integer          default(0)
#  revision_count       :integer          default(0)
#  stats                :text(65535)
#  last_mw_rev_datetime :datetime
#  needs_update         :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

FactoryBot.define do
  factory :course_wiki_timeslice, class: 'CourseWikiTimeslice' do
    nil
  end
end
