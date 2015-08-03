# == Schema Information
#
# Table name: gradeables
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  points              :integer
#  gradeable_item_id   :integer
#  created_at          :datetime
#  updated_at          :datetime
#  gradeable_item_type :string(255)
#

require 'rails_helper'

RSpec.describe Gradeable, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
