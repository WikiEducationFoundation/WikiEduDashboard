#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item
  before_destroy :cleanup

  def pretty_kind
    index = %w(Assignment Milestone Class Custom)
    index[kind]
  end

  def cleanup
    Gradeable.destroy gradeable_id unless gradeable_id.nil?
  end
end
