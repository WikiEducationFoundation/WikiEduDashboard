# frozen_string_literal: true

# == Schema Information
#
# Table name: article_course_timeslices
#
#  id                :bigint           not null, primary key
#  article_course_id :integer          not null
#  start             :datetime
#  end               :datetime
#  last_mw_rev_id    :integer
#  character_sum     :integer          default(0)
#  references_count  :integer          default(0)
#  user_ids          :text(65535)      default("")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ArticleCourseTimeslice < ApplicationRecord
  belongs_to :articles_courses
end
