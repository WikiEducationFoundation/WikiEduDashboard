# frozen_string_literal: true

require 'rails_helper'

describe AiEditAlertMailer do
  let(:course) { create(:course) }
  let(:instructor) { create(:user, email: 'instructor@example.com') }
  let(:student) { create(:user, username: 'Student', email: 'student@example.com') }

  before do
    create(:courses_user, user: instructor, course:,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    allow(Features).to receive(:email?).and_return(true)
  end

  def build_alert(article_title, extra_details = {})
    AiEditAlert.new(
      course:,
      user: student,
      details: {
        article_title:,
        pangram_prediction: 'Fully AI Generated',
        headline_result: 'Fully AI Generated',
        average_ai_likelihood: 0.97,
        max_ai_likelihood: 1.0,
        fraction_ai_content: 1.0,
        fraction_mixed_content: 0.0,
        predicted_ai_window_count: 3,
        pangram_share_link: 'https://www.pangram.com/history/example',
        prior_alert_count_for_course: 0,
        prior_exercise_alerts: 0,
        prior_sandbox_alerts: 0,
        prior_mainspace_alerts: 0,
        prior_omnibus_advice_sent: false
      }.merge(extra_details)
    )
  end

  describe '.send_instructor_advice' do
    it 'sends exercise advice for the first exercise alert' do
      alert = build_alert('User:Foo/Evaluate an Article')
      expect { described_class.send_instructor_advice(alert) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(ActionMailer::Base.deliveries.last.subject).to include('instructor next steps')
    end

    it 'skips exercise advice when prior_exercise_alerts > 0' do
      alert = build_alert('User:Foo/Evaluate an Article', prior_exercise_alerts: 1)
      expect { described_class.send_instructor_advice(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'sends sandbox advice for the first sandbox alert' do
      alert = build_alert('User:Foo/Sandbox')
      expect { described_class.send_instructor_advice(alert) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'skips sandbox advice when prior_sandbox_alerts > 0' do
      alert = build_alert('User:Foo/Sandbox', prior_sandbox_alerts: 1)
      expect { described_class.send_instructor_advice(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'sends mainspace advice for the first mainspace alert' do
      alert = build_alert('Artwork title')
      expect { described_class.send_instructor_advice(alert) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'skips mainspace advice when prior_mainspace_alerts > 0' do
      alert = build_alert('Artwork title', prior_mainspace_alerts: 1)
      expect { described_class.send_instructor_advice(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'skips all advice when prior_omnibus_advice_sent is true' do
      alert = build_alert('Artwork title', prior_omnibus_advice_sent: true)
      expect { described_class.send_instructor_advice(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'skips advice for non-advice page types' do
      alert = build_alert('Draft:Artwork title')
      expect { described_class.send_instructor_advice(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end
  end

  describe '.send_emails' do
    it 'returns early when email feature is disabled' do
      allow(Features).to receive(:email?).and_return(false)
      alert = build_alert('Artwork title')
      expect { described_class.send_emails(alert) }
        .not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'sends the regular email and calls send_instructor_advice' do
      alert = build_alert('Artwork title')
      expect(described_class).to receive(:send_instructor_advice).with(alert)
      expect { described_class.send_emails(alert) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
