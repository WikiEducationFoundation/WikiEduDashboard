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

describe ArticleScopedProgram, type: :model do
  describe 'update caches' do
    before do
      create(:courses_user,
             user_id: editor.id,
             course_id: asp.id,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:assignment, user_id: editor.id, course_id: asp.id,
                          article_id: 2, article_title: 'Assigned')

      allow(Replica).to receive(:new).and_return(replica_instance)
      allow(replica_instance).to receive(:get_revisions).and_return(revisions)
      VCR.use_cassette 'article_scoped_update' do
        UpdateCourseStats.new(asp)
      end
    end

    let(:asp) do
      create(:article_scoped_program,
             start: 2.days.ago,
             end: Time.zone.today + 2.days)
    end
    let(:editor) { create(:user) }
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
                'username' => editor.username, 'new_article' => 'false',
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
                'username' => editor.username, 'new_article' => 'false',
                'system' => 'false', 'wiki_id' => 1 }
            ]
          }
        ]
      ]
    end

    it 'onlies count assigned articles' do
      expect(asp.article_count).to eq(1)
    end

    it 'onlies generate ArticlesCourses for assigned articles' do
      expect(asp.articles_courses.count).to eq(1)
    end

    it 'onlies count revisions to assigned articles' do
      expect(asp.revision_count).to eq(1)
    end

    it 'onlies count characters for assigned articles' do
      expect(asp.character_sum).to eq(chars)
    end
  end

  describe '#scoped_article?' do
    before do
      create(:article, title: 'Category_article')
      unassigned_article # force creation
      create(:assignment, course:, article:, article_title: article.title, wiki:)
      create(:categories_courses, course:, category:)
    end

    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:article_scoped_program, start: '2018-01-01', end: '2018-12-31') }
    let(:category) { create(:category, wiki:, article_titles: ['Category_article']) }
    let(:article) { create(:article, title: 'Assigned_article') }
    let(:unassigned_article) { create(:article, title: 'Unassigned_article') }

    it 'considers articles in categories as scoped articles' do
      expect(course.scoped_article?(wiki, 'Category_article', 90)).to eq(true)
    end

    it 'considers assigned articles as scoped articles even though the title changed' do
      expect(course.scoped_article?(wiki, 'assigned article', article.mw_page_id)).to eq(true)
    end

    it 'returns false for unassigned articles' do
      mw_page_id = unassigned_article.mw_page_id
      expect(course.scoped_article?(wiki, 'Unassigned_article', mw_page_id)).to eq(false)
    end
  end

  # scoped_article? calls scoped_article_titles once per article of every fetched timeslice,
  # so rebuilding the list on each call is the dominant cost for a course with a large
  # scope. The memo below is what keeps that list from being rebuilt.
  describe '#scoped_article_titles' do
    before do
      stub_wiki_validation
      create(:assignment, course:, article:, article_title: article.title, wiki:)
      create(:categories_courses, course:, category:)
    end

    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:article_scoped_program, start: '2018-01-01', end: '2018-12-31') }
    let(:category) { create(:category, wiki:, article_titles: ['Category_article']) }
    let(:article) { create(:article, title: 'Assigned_article') }

    it 'includes both assigned and category article titles' do
      expect(course.scoped_article_titles(wiki))
        .to contain_exactly('Assigned_article', 'Category_article')
    end

    it 'returns the same object on repeated calls, without rebuilding the list' do
      expect(course.scoped_article_titles(wiki)).to equal(course.scoped_article_titles(wiki))
    end

    it 'returns a Set, so that looking a title up does not scan the whole scope' do
      expect(course.scoped_article_titles(wiki)).to be_a(Set)
    end

    it 'memoizes per wiki rather than for the whole course' do
      other_wiki = Wiki.get_or_create(language: 'es', project: 'wikipedia')
      course.scoped_article_titles(wiki)
      expect(course.scoped_article_titles(other_wiki)).to be_empty
    end

    it 'picks up category changes for a freshly loaded course' do
      course.scoped_article_titles(wiki)
      category.update(article_titles: %w[Category_article New_category_article])
      expect(Course.find(course.id).scoped_article_titles(wiki))
        .to include('New_category_article')
    end
  end
end
