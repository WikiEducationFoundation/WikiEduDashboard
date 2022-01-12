class CourseStat < ApplicationRecord
  belongs_to :course
  serialize :stats_hash, Hash
end
