# frozen_string_literal: true

require 'rails_helper'

describe PushCourseApplicationToSalesforceWorker do
  let(:application) do
    CourseApplication.create!(course: create(:fellows_cohort), user: create(:user))
  end

  it 'pushes the application' do
    allow(PushCourseApplicationToSalesforce).to receive(:new)
    described_class.new.perform(application.id)
    expect(PushCourseApplicationToSalesforce).to have_received(:new).with(application)
  end

  it 'does nothing for an application deleted since it was queued' do
    allow(PushCourseApplicationToSalesforce).to receive(:new)
    described_class.new.perform(0)
    expect(PushCourseApplicationToSalesforce).not_to have_received(:new)
  end
end
