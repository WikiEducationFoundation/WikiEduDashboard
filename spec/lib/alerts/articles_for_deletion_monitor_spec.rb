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
    let(:revision) do
      create(:revision, article_id: article.id,
                        user_id: student.id,
                        date: course.start + 1.day,
                        new_article: article_is_new)
    end
    let(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id,
                               new_article: article_is_new)
    end

    # PRODded article
    let(:prod) { create(:article, title: 'PRODded_page', namespace: 0) }
    let!(:prod_revision) do
      create(:revision, article_id: prod.id,
                        user_id: student.id,
                        date: course.start + 1.day,
                        new_article: article_is_new)
    end
    let!(:prod_articles_course) do
      create(:articles_course, article_id: prod.id,
                               course_id: course.id,
                               new_article: article_is_new)
    end

    before do
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
      before { articles_course && revision && courses_user }

      it 'creates Alert records for both AfD and PROD' do
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
        alerted_article_ids = Alert.all.pluck(:article_id)
        expect(alerted_article_ids).to include(article.id)
        expect(alerted_article_ids).to include(prod.id)
      end

      it 'emails a greeter' do
        create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
        allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.last.email_sent_at).not_to be_nil
      end

      it 'does not create a second Alert for the same articles' do
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: article.id, course_id: course.id)
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: prod.id, course_id: course.id)
        expect(Alert.count).to eq(2)
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
      end

      it 'does create second Alert if the first alert is resolved' do
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: article.id, course_id: course.id, resolved: true)
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: prod.id, course_id: course.id)
        expect(Alert.count).to eq(2)
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(3)
      end
    end

    context 'when there is not a new article' do
      let(:article_is_new) { false }
      before { articles_course && revision && courses_user }

      it 'does still creates an Alert record' do
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(2)
      end
    end
  end
end
