# frozen_string_literal: true
# == Schema Information
#
# Table name: course_stat
#
#  id          :integer
#  course_id   :integer
#  stats_hash  :text
#  created_at  :datetime
#  updated_at  :datetime

class CourseStat < ApplicationRecord
  belongs_to :course
  serialize :stats_hash, Hash
end
