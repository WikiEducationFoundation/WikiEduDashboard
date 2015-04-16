#= Week model
class Week < ActiveRecord::Base
  has_many :blocks
  has_many :gradeables, through: :blocks
end
