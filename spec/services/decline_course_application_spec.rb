# frozen_string_literal: true

require 'rails_helper'

describe DeclineCourseApplication do
  let(:course) { create(:fellows_cohort) }
  let(:staff) { create(:admin) }
  let(:application) { CourseApplication.create!(course:, user: create(:user)) }

  before { allow(CourseApplicationMailer).to receive(:send_decline) }

  it 'declines a submitted application and emails the applicant' do
    described_class.new(application:, staff:)
    expect(application.reload).to be_declined
    expect(application.decided_by).to eq(staff)
    expect(application.decided_at).to be_present
    expect(CourseApplicationMailer).to have_received(:send_decline).with(application)
  end

  it 'sends nothing for an application already declined' do
    application.update!(status: :declined)
    described_class.new(application:, staff:)
    expect(CourseApplicationMailer).not_to have_received(:send_decline)
  end

  it 'refuses, sending nothing, once an admin has added the applicant to the course' do
    create(:courses_user, course:, user: application.user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    described_class.new(application:, staff:)
    expect(application.reload).to be_submitted
    expect(CourseApplicationMailer).not_to have_received(:send_decline)
  end

  it 'leaves an accepted application accepted' do
    application.update!(status: :accepted)
    described_class.new(application:, staff:)
    expect(application.reload).to be_accepted
    expect(application.decided_by).to be_nil
    expect(CourseApplicationMailer).not_to have_received(:send_decline)
  end
end
