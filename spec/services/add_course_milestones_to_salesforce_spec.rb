# frozen_string_literal: true
require 'rails_helper'

describe AddCourseMilestonesToSalesforce do
  let(:course) { create(:course, flags: { salesforce_id: 'a2qQ0101015h4HF' }) }
  let(:subject) { described_class.new(course) }
  let(:week) { create(:week, course: course) }

  context 'when the course has editing and mainspace blocks' do
    before do
      create(:block, week: week, title: 'Draft your article')
      create(:block, week: week, title: 'Begin moving your work to Wikipedia')
    end

    it 'calls #create! on the Restforce client for each of those milestones' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:create!).twice
      subject
    end
  end

  context 'when the course lacks editing and mainspace blocks' do
    before do
      create(:block, week: week, title: 'Play around')
      create(:block, week: week, title: 'Do not do write a Wikipedia article')
    end

    it 'does not create any milestones' do
      expect_any_instance_of(Restforce::Data::Client).not_to receive(:create!)
      subject
    end
  end
end
