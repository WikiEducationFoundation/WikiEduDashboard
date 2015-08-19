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

describe Block, type: :model do
  describe '#cleanup' do
    it 'should the associated Gradeable' do
      create(:block,
             id: 1,
             gradeable_id: 1,
             kind: 1)
      create(:gradeable,
             id: 1,
             gradeable_item_id: 1)
      Block.find(1).cleanup
      expect(Gradeable.exists?(1)).to be false
    end
  end
end
