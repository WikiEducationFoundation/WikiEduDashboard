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

describe VisitingScholarship, type: :model do
  describe 'update caches' do
    before do
      vs = create(:visiting_scholarship,
                  id: 10001,
                  start: 1.year.ago,
                  end: Time.zone.today + 1.year)
      scholar = create(:user)
      create(:courses_user,
             user_id: scholar.id,
             course_id: vs.id,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      random_article = create(:article, title: 'Random', id: 1, namespace: 0)
      assigned_article = create(:article, title: 'Assigned', id: 2, namespace: 0)
      create(:assignment, user_id: scholar.id, course_id: vs.id,
                          article_id: 2, article_title: 'Assigned')
      create(:revision, id: 1, user_id: scholar.id,
                        article_id: random_article.id, date: 1.day.ago)
      create(:revision, id: 2, user_id: scholar.id,
                        article_id: assigned_article.id, date: 1.day.ago)
      ArticlesCourses.update_from_course(vs)
      ArticlesCourses.update_all_caches(vs.articles_courses)
      CoursesUsers.update_all_caches(CoursesUsers.ready_for_update)
      Course.update_all_caches
    end

    let(:out_of_scope_rev) { Revision.find(1) }
    let(:in_scope_rev) { Revision.find(2) }
    let(:vs) { Course.find(10001) }

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
      expect(vs.character_sum).to eq(in_scope_rev.characters)
    end
  end

  describe '#filter_revisions' do
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
      course.filter_revisions(revisions)
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
