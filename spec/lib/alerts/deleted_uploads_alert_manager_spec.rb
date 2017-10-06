# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/deleted_uploads_alert_manager"

describe DeletedUploadsAlertManager do
  let(:course) { create(:course) }
  let(:subject) { DeletedUploadsAlertManager.new([course]) }
  let(:user) { create(:user) }
  let!(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: user.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
  end
  let(:create_deleted_uploads) do
    deleted_count.times do
      create(:commons_upload, user_id: user.id, uploaded_at: course.start + 1.day,
                              deleted: true)
    end
  end

  context 'when there are few deleted uploads' do
    let(:deleted_count) { 2 }
    it 'does not create an alert' do
      create_deleted_uploads
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when there are many deleted uploads' do
    let(:deleted_count) { 100 }
    it 'creates an alert' do
      create_deleted_uploads
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end
  end
end
