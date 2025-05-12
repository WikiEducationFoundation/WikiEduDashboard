# frozen_string_literal: true
# == Schema Information
#
# Table name: courses
#
#  id                    :integer          not null, primary key
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  start                 :datetime
#  end                   :datetime
#  school                :string(255)
#  term                  :string(255)
#  character_sum         :integer          default(0)
#  view_sum              :bigint           default(0)
#  user_count            :integer          default(0)
#  article_count         :integer          default(0)
#  revision_count        :integer          default(0)
#  slug                  :string(255)
#  subject               :string(255)
#  expected_students     :integer
#  description           :text(65535)
#  submitted             :boolean          default(FALSE)
#  passcode              :string(255)
#  timeline_start        :datetime
#  timeline_end          :datetime
#  day_exceptions        :string(2000)     default("")
#  weekdays              :string(255)      default("0000000")
#  new_article_count     :integer          default(0)
#  no_day_exceptions     :boolean          default(FALSE)
#  trained_count         :integer          default(0)
#  cloned_status         :integer
#  type                  :string(255)      default("ClassroomProgramCourse")
#  upload_count          :integer          default(0)
#  uploads_in_use_count  :integer          default(0)
#  upload_usages_count   :integer          default(0)
#  syllabus_file_name    :string(255)
#  syllabus_content_type :string(255)
#  syllabus_file_size    :bigint
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#  withdrawn             :boolean          default(FALSE)
#  references_count      :integer          default(0)
#

require 'rails_helper'
require "#{Rails.root}/lib/replica"

describe VisitingScholarship, type: :model do
  describe 'update caches' do
    before do
      create(:courses_user,
             user_id: scholar.id,
             course_id: vs.id,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:assignment, user_id: scholar.id, course_id: vs.id,
                          article_id: 2, article_title: 'Assigned')

      allow(Replica).to receive(:new).and_return(replica_instance)
      allow(replica_instance).to receive(:get_revisions).and_return(revisions)
      VCR.use_cassette 'course_update' do
        UpdateCourseStatsTimeslice.new(vs)
      end
    end

    let(:vs) do
      create(:visiting_scholarship,
             start: 2.days.ago,
             end: Time.zone.today + 2.days)
    end
    let(:scholar) { create(:user) }
    let(:random_article) { create(:article, title: 'Random', namespace: 0) }
    let(:assigned_article) { create(:article, title: 'Assigned', namespace: 0) }
    let(:replica_instance) { instance_double(Replica) }
    let(:chars) { 1234 }
    let(:revisions) do
      [
        [
          random_article.mw_page_id.to_s,
          {
            'article' => {
              'mw_page_id' => random_article.mw_page_id.to_s,
              'title' => random_article.title,
              'namespace' => '0',
              'wiki_id' => 1
            },
            'revisions' => [
              { 'mw_rev_id' => '849116430', 'date' => 1.day.ago.strftime('%Y%m%d'),
                'characters' => '569', 'mw_page_id' => random_article.mw_page_id.to_s,
                'username' => scholar.username, 'new_article' => 'false',
                'system' => 'false', 'wiki_id' => 1 }
            ]
          }
        ],
        [
          assigned_article.mw_page_id.to_s,
          {
            'article' => {
              'mw_page_id' => assigned_article.mw_page_id.to_s,
              'title' => assigned_article.title,
              'namespace' => '0',
              'wiki_id' => 1
            },
            'revisions' => [
              { 'mw_rev_id' => '849116431', 'date' => 1.day.ago.strftime('%Y%m%d'),
                'characters' => chars, 'mw_page_id' => assigned_article.mw_page_id.to_s,
                'username' => scholar.username, 'new_article' => 'false',
                'system' => 'false', 'wiki_id' => 1 }
            ]
          }
        ]
      ]
    end

    it 'onlies count assigned articles' do
      expect(vs.article_count).to eq(1)
    end

    it 'onlies generate ArticlesCourses for assigned articles' do
      expect(vs.articles_courses.count).to eq(1)
    end

    it 'onlies count revisions to assigned articles' do
      expect(vs.revision_count).to eq(1)
    end

    it 'onlies count characters for assigned articles' do
      expect(vs.character_sum).to eq(chars)
    end
  end

  describe '#filter_revisions' do
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:visiting_scholarship, start: '2018-01-01', end: '2018-12-31') }
    let(:user) { create(:user, username: 'Ragesoss') }
    let(:revisions) do
      [
        [
          '112',
          {
            'article' => {
              'mw_page_id' => '777',
              'title' => 'Some title',
              'namespace' => '4',
              'wiki_id' => 1
            },
            'revisions' => [
              { 'mw_rev_id' => '849116430', 'date' => '20180706', 'characters' => '569',
                'mw_page_id' => '777', 'username' => 'Ragesoss', 'new_article' => 'false',
                'system' => 'false', 'wiki_id' => 1 }
            ]
          }
        ],
        [
          '789',
          {
            'article' => {
              'mw_page_id' => '123',
              'title' => 'Important article',
              'namespace' => '118',
              'wiki_id' => 1
            },
            'revisions' => [
              { 'mw_rev_id' => '456', 'date' => '20180706', 'characters' => '569',
                'mw_page_id' => '123', 'username' => 'Ragesoss', 'new_article' => 'false',
                'system' => 'false', 'wiki_id' => 1 }
            ]
          }
        ]
      ]
    end
    let(:subject) do
      course.filter_revisions(wiki, revisions)
    end

    before do
      create(:courses_user, course:, user:)
      create(:article, id: 1, title: 'Important article', mw_page_id: 123, wiki_id: 1,
             namespace: 118)
      create(:assignment, course:, user:, article_id: 1, article_title: 'Important article')
    end

    it 'only returns revisions for assignments' do
      revisions = subject
      # Returns only revisions for assignments
      expect(revisions.length).to eq(1)
      expect(revisions[0][1]['article']['title']).to eq('Important article')
    end
  end
end
