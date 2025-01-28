# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/g_a_nomination_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe GANominationMonitor do
  describe '.create_alerts_for_course_articles' do
    let(:course) { create(:course) }
    let(:student) { create(:user, username: 'student') }
    let(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true) }

    # Article that hasn't been edited by students
    let!(:article2) { create(:article, title: '17776', namespace: 0) }

    # Good Article article
    let(:article) { create(:article, title: 'Be_Here_Now_(George_Harrison_song)', namespace: 0) }
    let(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id,
                               user_ids: [student.id]) # Add user_ids for testing user_id logic
    end

    before do
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Good article nominees', 0)
        .and_return(['Talk:Be Here Now (George Harrison song)',
                     'Talk:2017–18 London & South East Premier',
                     'Talk:17776'])

      articles_course && courses_user # Ensure `ArticlesCourses` and `CoursesUser` are created
    end

    it 'creates an Alert record for the edited article' do
      described_class.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
      alerted_article_ids = Alert.all.pluck(:article_id)
      expect(alerted_article_ids).to include(article.id)
    end

    it 'assigns user_id from articles_course.user_ids.first' do
      described_class.create_alerts_for_course_articles
      alert = Alert.find_by(article_id: article.id)

      expect(alert.user_id).to eq(student.id) # First user_id from user_ids
    end

    it 'does not depend on revisions for creating alerts' do
      described_class.create_alerts_for_course_articles
      alert = Alert.find_by(article_id: article.id)

      expect(alert).not_to be_nil
      expect(alert.revision_id).to be_nil # revision_id is not required
    end

    it 'emails a content expert' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      described_class.create_alerts_for_course_articles
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same articles' do
      Alert.create(type: 'GANominationAlert', article_id: article.id, course_id: course.id)
      expect(Alert.count).to eq(1)
      described_class.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
    end

    it 'does create a second Alert if the first alert is resolved' do
      Alert.create(type: 'GANominationAlert', article_id: article.id,
                   course_id: course.id, resolved: true)
      expect(Alert.count).to eq(1)
      described_class.create_alerts_for_course_articles
      expect(Alert.count).to eq(2)
    end
  end
end
