# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

require 'rails_helper'

describe OverdueTrainingAlert do
  let(:course) { create(:course) }
  let(:student) { create(:user, email: 'student@example.edu') }
  before do
    TrainingModule.load_all
    create(:user_profile, user: student, email_preferences:)
  end

  let(:alert) do
    create(:overdue_training_alert,
           user: student, course:,
           details: { 'plagiarism' => { due_date: 1.day.ago,
                                        status: 'overdue',
                                        progress: '85% Complete' } })
  end

  describe '#send_email' do
    let(:subject) { alert.send_email }

    context 'when the user has not opted out' do
      let(:email_preferences) { {} }

      it 'sends an email' do
        expect(alert.email_sent_at).to be_nil
        subject
        expect(alert.reload.email_sent_at).not_to be_nil
      end
    end

    context 'when the user has opted out' do
      let(:email_preferences) { { 'OverdueTrainingAlert' => false } }

      it 'does not send an email' do
        expect(OverdueTrainingAlertMailer).not_to receive(:send_email)
        subject
      end
    end
  end
end
