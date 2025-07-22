# frozen_string_literal: true
# == Schema Information
#
# Table name: course_stats
#
#  id         :bigint           not null, primary key
#  stats_hash :text(65535)
#  course_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CourseStat < ApplicationRecord
  belongs_to :course
  serialize :stats_hash, Hash
end
