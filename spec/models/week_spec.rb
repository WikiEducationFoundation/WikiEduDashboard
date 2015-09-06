# == Schema Information
#
# Table name: weeks
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

describe Week do
  describe '#cleanup' do
    it 'should destroy associated blocks' do
      create(:block,
             id: 1,
             week_id: 1)
      create(:block,
             id: 2,
             week_id: 1)
      week = create(:week,
                    id: 1)
      week.cleanup
      expect(Block.all).to be_empty
    end
  end
end
