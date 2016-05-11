require 'rails_helper'
require "#{Rails.root}/lib/articles_for_deletion_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ArticlesForDeletionMonitor do
  describe '.create_alerts_for_new_articles' do
    let(:course) { create(:course) }
    let(:student) { create(:user, username: 'student') }
    let(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true) }
    let(:article) { create(:article, title: 'One_page', namespace: 0) }
    let!(:article2) { create(:article, title: 'Another_page', namespace: 0) }

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

    before do
      expect_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .and_return(['Wikipedia:Articles for deletion/One page',
                     'Wikipedia:Articles for deletion/Another page',
                     'Category:Some category'])
    end

    context 'when there is a new article' do
      let(:article_is_new) { true }
      before { articles_course && revision && courses_user }

      it 'creates an Alert record' do
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(1)
        expect(Alert.last.revision_id).to eq(revision.id)
      end

      it 'emails a greeter' do
        create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
        expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.last.email_sent_at).not_to be_nil
      end

      it 'does not create a second Alert for the same article' do
        Alert.create(type: 'ArticlesForDeletionAlert', article_id: article.id, course_id: course.id)
        expect(Alert.count).to eq(1)
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(1)
      end
    end

    context 'when there is not a new article' do
      let(:article_is_new) { false }
      before { articles_course && revision && courses_user }

      it 'does still creates an Alert record' do
        ArticlesForDeletionMonitor.create_alerts_for_course_articles
        expect(Alert.count).to eq(1)
      end
    end
  end
end
