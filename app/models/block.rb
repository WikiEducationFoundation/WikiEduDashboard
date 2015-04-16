#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item
end
