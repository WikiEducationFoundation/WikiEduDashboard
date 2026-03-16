# frozen_string_literal: true

require 'rails_helper'

describe CourseApprovalMailer do
  let(:course) { create(:course, title: 'Foo Course') }
  let(:instructor) { create(:user, email: 'karen@example.edu') }

  describe '.send_approval_notification' do
    let(:mail) { described_class.send_approval_notification(course, instructor) }

    it 'delivers an email with an enrollment link' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.html_part.body).to include(escaped_slug(course.slug) + '?enroll=')
      expect(mail.to).to eq([instructor.email])
    end

    it 'includes locale parameter when campaign has a default language' do
      allow(Features).to receive(:email?).and_return(true)
      campaign = create(:campaign, default_language: 'es')
      course.campaigns << campaign
      mail = described_class.send_approval_notification(course, instructor)
      expect(mail.html_part.body).to include('&locale=es')
    end

    it 'omits locale parameter when campaign has no default language' do
      allow(Features).to receive(:email?).and_return(true)
      campaign = create(:campaign, default_language: nil)
      course.campaigns << campaign
      mail = described_class.send_approval_notification(course, instructor)
      expect(mail.html_part.body).not_to include('&locale=')
    end
  end
end
