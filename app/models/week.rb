#= Week model
class Week < ActiveRecord::Base
  belongs_to :course
  has_many :blocks
  has_many :gradeables, through: :blocks
end
