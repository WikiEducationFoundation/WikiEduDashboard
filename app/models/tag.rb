#= Tag model
class Tag < ActiveRecord::Base
  belongs_to :course
end
