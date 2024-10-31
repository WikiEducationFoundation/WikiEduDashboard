# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/de_userfying_edit_alert_monitor"
require "#{Rails.root}/lib/importers/article_importer"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe DeUserfyingEditAlertMonitor do
  let(:mntor) { described_class.new }
  let(:course1) { create(:course, slug: 'slug-one') }
  let(:course2) { create(:course, slug: 'slug-two') }
  let(:student1) { create(:user, username: 'alice', email: 'student1@example.edu') }
  let(:student2) { create(:user, username: 'bob', email: 'student2@example.edu') }
  let(:student3) { create(:user, username: 'carol', email: 'student3@example.edu') }
  let(:instructor1) { create(:user, username: 'sidney', email: 'instructor1@example.edu') }
  let(:article1) { create(:article, title: 'my title 1', mw_page_id: 111) }
  let(:article2) { create(:article, title: 'my title 2', mw_page_id: 222) }
  let(:content_expert) { create(:user, greeter: true) }
  let!(:student_role) { CoursesUsers::Roles::STUDENT_ROLE }
  let!(:instructor_role) { CoursesUsers::Roles::INSTRUCTOR_ROLE }
  let(:courses_users) do
    [
      { course_id: course1.id, user_id: student1.id, role: student_role },
      { course_id: course1.id, user_id: student3.id, role: student_role },
      { course_id: course2.id, user_id: student2.id, role: student_role },
      { course_id: course2.id, user_id: student3.id, role: student_role },
      { course_id: course1.id, user_id: instructor1.id, role: instructor_role },
      { course_id: course2.id, user_id: instructor1.id, role: instructor_role }
    ]
  end

  before do
    populate_users
  end

  describe '.edits' do
    it 'checks keys' do
      VCR.use_cassette 'recent_changes' do
        fedit = mntor.edits.first
        expect(fedit.dig('logparams', 'target_title')).not_to be_nil
        expect(fedit.dig('user')).not_to be_nil
        expect(fedit.dig('revid')).not_to be_nil
        expect(fedit.dig('pageid')).not_to be_nil
        expect(fedit.dig('logid')).not_to be_nil
        expect(fedit.dig('timestamp')).not_to be_nil
      end
    end
  end

  describe '.current_users' do
    it 'checks distinct enrolled users' do
      expect(mntor.current_users.count).to eq 4
    end
  end

  describe '.edits_made_by_users' do
    it 'filters users that de-userfyed their page' do
      allow(mntor).to receive(:edits).and_return(editsfeed)
      edits = mntor.edits
      users = mntor.current_users
      expect(mntor.edits_made_by_users(edits, users).count).to eq editsfeed.count
    end
  end

  describe '.create_alerts' do
    before do
      populate_content_expert
      populate_articles
      allow_any_instance_of(described_class).to receive(:edits).and_return(editsfeed)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
    end

    it 'emails a content expert per edit' do
      described_class.create_alerts_for_deuserfying_edits
      expect(Alert.all.pluck(:email_sent_at).compact.count).to eq editsfeed.count
    end

    it 'does not create a third Alert' do
      Alert.create(type: 'DeUserfyingAlert',
                   course_id: course1.id,
                   article_id: article1.id,
                   revision_id: editsfeed.first['revid'])
      expect(Alert.count).to eq(1)
      mntor.create_alerts
      expect(Alert.count).to eq editsfeed.count
    end

    context 'When neither article fetch or created' do
      it 'creates an alert with nil article' do
        allow(mntor).to receive(:article_by_mw_page_id)
        mntor.create_alerts
        expect(Alert.first.article_id).to eq nil
      end
    end
  end

  describe '.courses_for_a_student' do
    it 'checks course(s) for a given student' do
      expect(mntor.courses_for_user(student1))
        .to eq courses_users
          .filter { |cu| cu[:user_id] == student1.id }
          .pluck(:course_id)
    end
  end

  describe '.courses_for_an_instructor' do
    it 'checks course(s) for a given instructor' do
      expect(mntor.courses_for_user(instructor1))
        .to eq courses_users
          .filter { |cu| cu[:user_id] == instructor1.id }
          .pluck(:course_id)
    end
  end

  describe '.article_by_mw_page_id' do
    context 'When no matching article in db' do
      before do
        allow(ArticleImporter).to receive(:new).and_return(importer)
      end

      let(:importer) { instance_double(ArticleImporter) }

      it 'tries to import from wikipedia' do
        expect(importer).to receive(:import_articles).with([7777])
        mntor.article_by_mw_page_id(7777)
      end
    end

    context 'When a matching article in db' do
      it 'finds the article' do
        expect(mntor.article_by_mw_page_id(article1.mw_page_id)).to eq Article.first
      end
    end
  end

  private

  # Some students and instructors should be enrolled in multiple courses to make
  # the test effective.
  def populate_users
    CoursesUsers.create(courses_users)
  end

  def editsfeed
    [{ 'user' => 'alice', 'revid' => 12, 'pageid' => 111,
       'logparams' => { 'target_title' => 'my title 1' } },
     { 'user' => 'bob', 'revid' => 447, 'pageid' => 222,
       'logparams' => { 'target_title' => 'my title 2' } }]
  end

  def populate_content_expert
    create(:courses_user,
           user_id: content_expert.id,
           course_id: course1.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    create(:courses_user,
           user_id: content_expert.id,
           course_id: course2.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  def populate_articles
    article1
    article2
  end
end
