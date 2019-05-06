# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/high_quality_article_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe HighQualityArticleMonitor do
  describe '.create_alerts_for_course_articles' do
    let(:course) { create(:course) }
    let(:student) { create(:user, username: 'student') }
    let!(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true) }

    # Good article that hasn't been edited by students
    let!(:article2) { create(:article, title: 'History_of_aspirin', namespace: 0) }

    # Featured article edited by student
    let(:article) { create(:article, title: 'Phan_Đình_Phùng', namespace: 0) }
    let!(:revision) do
      create(:revision, article_id: article.id,
                        user_id: student.id,
                        date: course.start + 1.day)
    end
    let!(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id)
    end

    before do
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Good articles')
        .and_return(['10 Hygiea',
                     'History of aspirin',
                     'Goshin'])
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Featured articles')
        .and_return(["Petter's big-footed mouse",
                     'Phan Đình Phùng',
                     'The Phantom Tollbooth'])
    end

    it 'creates Alert records for edited Good articles' do
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleEditAlert.count).to eq(1)
      alerted_article_ids = HighQualityArticleEditAlert.all.pluck(:article_id)
      expect(alerted_article_ids).to include(article.id)
    end

    it 'emails a greeter' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same articles, if the first is not resolved' do
      Alert.create(type: 'HighQualityArticleEditAlert',
                   article_id: article.id, course_id: course.id)
      expect(HighQualityArticleEditAlert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleEditAlert.count).to eq(1)
    end

    it 'does not create second Alert if the first alert is resolved but there are no new edits' do
      Alert.create(type: 'HighQualityArticleEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: revision.date + 1.hour)
      expect(Alert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(Alert.count).to eq(1)
    end

    it 'does create second Alert if the first alert is resolved and there are later edits' do
      Alert.create(type: 'HighQualityArticleEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: revision.date - 1.hour)
      expect(Alert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(Alert.count).to eq(2)
    end
  end
end
