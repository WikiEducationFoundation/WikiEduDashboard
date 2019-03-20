# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'has a valid factory' do
    message = build(:message)
    expect(message).to be_valid
  end

  describe 'validations and associations' do
    let(:message) { build(:message) }

    it { expect(message).to validate_numericality_of(:kind) }
    it {
      values = Message::Kinds.constants.map { |c| Message::Kinds.const_get c }
      higher_val = values.max + 1
      expect(message).not_to allow_value(higher_val).for(:kind)
    }
    it { expect(message).to validate_presence_of(:read) }

    it { expect(message).not_to allow_value(nil).for(:content) }
    it { expect(message).to allow_value('').for(:content) }
    it { expect(message).to allow_value('Hello').for(:content) }

    it { expect(message).to belong_to(:sender) }
    it { expect(message).to belong_to(:ticket) }
  end
end
