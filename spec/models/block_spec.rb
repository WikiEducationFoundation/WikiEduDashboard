# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  kind         :integer
#  content      :string(5000)
#  week_id      :integer
#  gradeable_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#  title        :string(255)
#  order        :integer
#  duration     :integer          default(1)
#

require 'rails_helper'

RSpec.describe Block, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
