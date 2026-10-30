# frozen_string_literal: true

require 'rails_helper'

describe DeclineCourseApplication do
  let(:course) { create(:fellows_cohort) }
  let(:staff) { create(:admin) }
  let(:application) { CourseApplication.create!(course:, user: create(:user)) }

  it 'declines a submitted application' do
    described_class.new(application:, staff:)
    expect(application.reload).to be_declined
    expect(application.decided_by).to eq(staff)
    expect(application.decided_at).to be_present
  end

  it 'leaves an accepted application accepted' do
    application.update!(status: :accepted)
    described_class.new(application:, staff:)
    expect(application.reload).to be_accepted
    expect(application.decided_by).to be_nil
  end
end
