# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/discretionary_sanctions_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe DiscretionarySanctionsMonitor do
  describe '.create_alerts_for_course_articles' do
    let(:course) { create(:course) }
    let(:student) { create(:user, username: 'student') }
    let!(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:content_expert) { create(:user, greeter: true) }

    # Article that hasn't been edited by students
    let!(:article2) { create(:article, title: '1948_war', namespace: 0) }

    # Article that has been edited by a student
    let(:article) { create(:article, title: 'Ahmed_Mohamed_clock_incident', namespace: 0) }
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
        .with('Category:Wikipedia pages under discretionary sanctions', 1)
        .and_return(['Talk:1948 war',
                     'Talk:Ahmed Mohamed clock incident',
                     'Talk:Armenian Genocide denial'])
    end

    it 'creates Alert records for edited articles under discretionary sanctions' do
      DiscretionarySanctionsMonitor.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
      alerted_article_ids = Alert.all.pluck(:article_id)
      expect(alerted_article_ids).to include(article.id)
    end

    it 'emails a greeter' do
      create(:courses_user, user_id: content_expert.id, course_id: course.id, role: 4)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      DiscretionarySanctionsMonitor.create_alerts_for_course_articles
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same articles, if the first is not resolved' do
      Alert.create(type: 'DiscretionarySanctionsEditAlert',
                   article_id: article.id, course_id: course.id)
      expect(Alert.count).to eq(1)
      DiscretionarySanctionsMonitor.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
    end

    it 'does not create second Alert if the first alert is resolved but there are no new edits' do
      Alert.create(type: 'DiscretionarySanctionsEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: revision.date + 1.hour)
      expect(Alert.count).to eq(1)
      DiscretionarySanctionsMonitor.create_alerts_for_course_articles
      expect(Alert.count).to eq(1)
    end

    it 'does create second Alert if the first alert is resolved and there are later edits' do
      Alert.create(type: 'DiscretionarySanctionsEditAlert', article_id: article.id,
                   course_id: course.id, resolved: true, created_at: revision.date - 1.hour)
      expect(Alert.count).to eq(1)
      DiscretionarySanctionsMonitor.create_alerts_for_course_articles
      expect(Alert.count).to eq(2)
    end
  end
end
