# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/high_quality_article_monitor"

describe HighQualityArticleMonitor do
  describe '.create_alerts_for_course_articles' do
    let(:course) { create(:course, start: '2024-01-01', end: 30.days.from_now) }
    let(:student) { create(:user, username: 'Leemyongpak', email: 'learn@school.edu') }
    let(:instructor) { create(:user, username: 'instructor', email: 'teach@school.edu') }
    let!(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true, email: 'expert@wikiedu.org') }

    # Good article that hasn't been edited by students
    let!(:article2) { create(:article, title: 'History_of_aspirin', namespace: 0) }

    # Featured article edited by student
    let(:article) { create(:article, title: 'Phan_Đình_Phùng', mw_page_id: 10771083, namespace: 0) }
    let!(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id,
                               user_ids: [student.id, 45])
    end
    let!(:assignment) do
      create(:assignment, article_title: article.title,
                          article_id: article.id,
                          course_id: course.id,
                          user_id: student.id)
    end

    before do
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

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
      described_class.create_alerts_for_course_articles
      expect(HighQualityArticleEditAlert.count).to eq(1)
      expect(HighQualityArticleAssignmentAlert.count).to eq(1)
      alerted_edit_article_ids = HighQualityArticleEditAlert.all.pluck(:article_id)
      expect(alerted_edit_article_ids).to include(article.id)
      alerted_edit_user_ids = HighQualityArticleEditAlert.all.pluck(:user_id)
      expect(alerted_edit_user_ids).to include(student.id)
      alerted_assignment_article_ids = HighQualityArticleAssignmentAlert.all.pluck(:article_id)
      expect(alerted_assignment_article_ids).to include(article.id)
    end

    it 'emails a greeter' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      described_class.create_alerts_for_course_articles
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same assignments, if the first is not resolved' do
      Alert.create(type: 'HighQualityArticleAssignmentAlert', article_id: assignment.article_id,
                   course_id: assignment.course_id, user_id: assignment.user_id)
      expect(HighQualityArticleAssignmentAlert.count).to eq(1)
      described_class.create_alerts_for_course_articles
      expect(HighQualityArticleAssignmentAlert.count).to eq(1)
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
                   course_id: course.id, resolved: true, created_at: course.end - 1.minute)
      expect(HighQualityArticleEditAlert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleEditAlert.count).to eq(1)
    end

    it 'does not create second Alert if the first alert is resolved but no new student edits' do
      Alert.create(type: 'HighQualityArticleEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: course.start + 2.months)
      expect(HighQualityArticleEditAlert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleEditAlert.count).to eq(1)
    end

    it 'does create second Alert if the first alert is resolved and later student edits' do
      Alert.create(type: 'HighQualityArticleEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: course.start + 1.minute)
      expect(HighQualityArticleEditAlert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleEditAlert.count).to eq(2)
    end

    it 'does create second Alert if the first alert is resolved and there are later assignments' do
      Alert.create(type: 'HighQualityArticleAssignmentAlert', article_id: assignment.article_id,
                   course_id: assignment.course_id, user_id: assignment.user_id, resolved: true)
      expect(HighQualityArticleAssignmentAlert.count).to eq(1)
      VCR.use_cassette 'high_quality' do
        described_class.create_alerts_for_course_articles
      end
      expect(HighQualityArticleAssignmentAlert.count).to eq(2)
    end
  end
end
