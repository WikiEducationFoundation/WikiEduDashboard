# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/due_date"

describe DueDate do
  describe '.passed?' do
    let(:due) { Date.new(2026, 10, 12) }

    it 'is false without a date' do
      expect(described_class.passed?(nil)).to be(false)
    end

    it 'is false on the evening of the due date in the Americas' do
      travel_to(Time.utc(2026, 10, 13, 1)) { expect(described_class.passed?(due)).to be(false) }
    end

    it 'is false until the due date has ended in UTC−12' do
      travel_to(Time.utc(2026, 10, 13, 11, 59)) do
        expect(described_class.passed?(due)).to be(false)
      end
    end

    it 'is true once the due date has ended in UTC−12' do
      travel_to(Time.utc(2026, 10, 13, 12)) { expect(described_class.passed?(due)).to be(true) }
    end
  end
end
