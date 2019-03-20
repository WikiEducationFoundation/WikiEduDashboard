# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ticket, type: :model do
  it 'has a valid factory' do
    ticket = build(:ticket)
    expect(ticket).to be_valid
  end

  describe 'validations and associations' do
    let(:ticket) { build(:ticket) }

    it { expect(ticket).to validate_numericality_of(:status) }
    it {
      values = Ticket::Statuses.constants.map { |c| Ticket::Statuses.const_get c }
      higher_val = values.max + 1
      expect(ticket).not_to allow_value(higher_val).for(:status)
    }

    it { expect(ticket).to belong_to(:course) }
    it { expect(ticket).to belong_to(:owner) }
  end
end
