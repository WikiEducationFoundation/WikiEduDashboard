# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/d_y_k_nomination_monitor"

describe DYKNominationMonitor do
  describe '.create_alerts_for_course_articles' do
    let(:course) { create(:course, end: 1.week.from_now) }
    let(:student) { create(:user, username: 'student') }
    let(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true, email: 'staff@wikiedu.org') }
    let(:instructor) { create(:user, email: 'teach@wiki.edu') }

    # Article that hasn't been edited by students
    let!(:article2) { create(:article, title: '17776', namespace: 0) }

    # DYK article
    let(:article) { create(:article, title: 'Venus_and_Adonis_(Titian)', namespace: 0) }
    let(:articles_course) do
      create(:articles_course, article_id: article.id,
                               course_id: course.id,
                               user_ids: [student.id]) # Add user_ids for testing user_id logic
    end

    before do
      allow_any_instance_of(CategoryImporter).to receive(:page_titles_for_category)
        .with('Category:Pending DYK nominations', 0, Article::Namespaces::TEMPLATE)
        .and_return(['Template:Did you know nominations/Venus and Adonis (Titian)',
                     'Template:Did you know nominations/2017–18 London & South East Premier',
                     'Template:Did you know nominations/17776'])

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

    it 'emails a greeter' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      described_class.create_alerts_for_course_articles
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'emails course creator' do
      create(:courses_user, user: instructor, course:,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      described_class.create_alerts_for_course_articles
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same articles' do
      Alert.create(type: 'DYKNominationAlert', article_id: article.id, course_id: course.id)
      expect(Alert.count).to eq(1)
      described_class.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
    end

    it 'does create a second Alert if the first alert is resolved' do
      Alert.create(type: 'DYKNominationAlert', article_id: article.id,
                   course_id: course.id, resolved: true)
      expect(Alert.count).to eq(1)
      described_class.create_alerts_for_course_articles
      expect(Alert.count).to eq(2)
    end
  end
end
