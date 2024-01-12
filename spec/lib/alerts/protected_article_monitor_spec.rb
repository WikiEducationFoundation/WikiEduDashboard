# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/alerts/protected_article_monitor')

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ProtectedArticleMonitor do
  describe '.create_alerts_for_assigned_articles' do
    let(:course) { create(:course, start: 1.month.ago, end: 1.month.after) }
    let(:student) { create(:user, username: 'student') }
    let!(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true) }

    # Protected article
    let(:article) { create(:article, title: 'Moldavia', namespace: 0) }
    let!(:assignment) do
      create(:assignment, article_title: article.title,
                          article_id: article.id,
                          course_id: course.id,
                          user_id: student.id)
    end

    before do
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Wikipedia fully protected pages')
        .and_return(['Moldavia'])
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Wikipedia extended-confirmed-protected pages')
        .and_return(['1973 oil crisis'])
    end

    it 'creates Alert records for assigned protected article' do
      VCR.use_cassette 'protected_articles' do
        described_class.create_alerts_for_assigned_articles
      end
      expect(ProtectedArticleAssignmentAlert.count).to eq(1)
      alerted_assignment_article_ids = ProtectedArticleAssignmentAlert.all.pluck(:article_id)
      expect(alerted_assignment_article_ids).to include(article.id)
    end

    it 'emails a greeter' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      VCR.use_cassette 'protected_articles' do
        described_class.create_alerts_for_assigned_articles
      end
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same assignments' do
      Alert.create(type: 'ProtectedArticleAssignmentAlert', article_id: assignment.article_id,
                   course_id: assignment.course_id, user_id: assignment.user_id)
      expect(ProtectedArticleAssignmentAlert.count).to eq(1)
      VCR.use_cassette 'protected_articles' do
        described_class.create_alerts_for_assigned_articles
      end
      expect(ProtectedArticleAssignmentAlert.count).to eq(1)
    end
  end
end
