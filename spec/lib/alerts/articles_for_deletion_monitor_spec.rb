# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/articles_for_deletion_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ArticlesForDeletionMonitor do
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
    let!(:article2) { create(:article, title: 'Another_page', namespace: 0) }

    # AFD article
    let(:article) { create(:article, title: 'One_page', namespace: 0) }
    let(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id,
                               new_article: article_is_new,
                               user_ids: [student.id])
    end

    # PRODded article
    let(:prod) { create(:article, title: 'PRODded_page', namespace: 0) }
    let!(:prod_articles_course) do
      create(:articles_course, article_id: prod.id,
                               course_id: course.id,
                               new_article: article_is_new,
                               user_ids: [student.id])
    end

    before do
      described_class.enable_for(Wiki.find(1),
                                 afd: 'Category:AfD debates',
                                 afd_prefix: 'Wikipedia:Articles for deletion/',
                                 prod: 'Category:All articles proposed for deletion',
                                 speedy: 'Category:Speedy deletion')

      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:AfD debates', 2)
        .and_return(['Wikipedia:Articles for deletion/One page',
                     'Wikipedia:Articles for deletion/Another page',
                     'Category:Some category'])
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:All articles proposed for deletion', 0)
        .and_return(['PRODded page',
                     'Mr. Pakistan World'])
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Speedy deletion', 1)
        .and_return(['Speedy 1', 'Speedy 2'])
    end

    context 'when there is a new article' do
      let(:article_is_new) { true }

      before { articles_course && courses_user }

      it 'creates Alert records for both AfD and PROD' do
        described_class.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
        alerted_article_ids = Alert.all.pluck(:article_id)
        expect(alerted_article_ids).to include(article.id)
        expect(alerted_article_ids).to include(prod.id)
      end

      it 'assigns user_id from articles_course.user_ids.first' do
        described_class.create_alerts_for_course_articles
        alert = Alert.find_by(article_id: article.id)

        expect(alert.user_id).to eq(student.id) # First user_id from user_ids
      end

      it 'creates Alert records without requiring revisions' do
        described_class.create_alerts_for_course_articles
        alert = Alert.find_by(article_id: article.id)

        expect(alert).not_to be_nil
        expect(alert.revision_id).to be_nil # revision_id should not matter
      end

      it 'emails a greeter' do
        create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
        allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
        described_class.create_alerts_for_course_articles
        expect(Alert.last.email_sent_at).not_to be_nil
      end

      it 'does not create a second Alert for the same articles' do
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: article.id, course_id: course.id)
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: prod.id, course_id: course.id)
        expect(Alert.count).to eq(2)
        described_class.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
      end

      it 'does create a second Alert if the first alert is resolved' do
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: article.id,
                     course_id: course.id, resolved: true)
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: prod.id, course_id: course.id)
        expect(Alert.count).to eq(2)
        described_class.create_alerts_for_course_articles
        expect(Alert.count).to eq(3)
      end
    end

    context 'when there is not a new article' do
      let(:article_is_new) { false }

      before { articles_course && courses_user }

      it 'still creates an Alert record' do
        described_class.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
      end
    end
  end
end
