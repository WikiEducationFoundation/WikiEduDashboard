#= Gradeable model
class Gradeable < ActiveRecord::Base
  belongs_to :gradeable_item, polymorphic: true
end
