#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item

  def pretty_kind
    index = %w(Assignment Milestone Class Custom)
    index[kind]
  end
end
