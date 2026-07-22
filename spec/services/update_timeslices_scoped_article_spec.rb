# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe UpdateTimeslicesScopedArticle do
  before { stub_const('TimesliceManager::TIMESLICE_DURATION', 86400) }

  let(:course) { create(:article_scoped_program) }
  let(:basic_course) { create(:course) }
  let(:assigned_article) { create(:article, title: 'Assigned', id: 2, namespace: 0) }
  let(:random_article) { create(:article, title: 'Random', id: 1, namespace: 0) }

  # Legacy path: course without use_acuwt? set
  context 'for ArticleScopedProgram (legacy path)' do
    before do
      enwiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
      user = create(:user, username: 'Ragesoss')
      create(:assignment, user_id: user.id, course_id: course.id, article_id: 2,
            article_title: 'Assigned')
      manager = TimesliceManager.new(course)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])

      create(:article_course_timeslice, course:, article: random_article,
            start: course.start + 1.day)
      create(:article_course_timeslice, course:, article: assigned_article,
            start: course.start)
    end

    it 'sets timeslices as needs_update for new scoped articles' do
      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(1)
      expect(course.course_wiki_timeslices.find_by(needs_update: true).start).to eq(course.start)
      expect(course.article_course_timeslices.where(article_id: assigned_article.id).count).to eq(0)
    end

    it 'sets timeslices as needs_update for old scoped articles' do
      create(:articles_course, course:, article: assigned_article)
      create(:articles_course, course:, article: random_article)
      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(1)
      expect(course.course_wiki_timeslices.find_by(needs_update: true).start)
        .to eq(course.start + 1.day)
      expect(course.article_course_timeslices.where(article_id: random_article.id).count).to eq(0)
      expect(course.articles_courses.count).to eq(1)
      expect(course.articles_courses.where(article_id: random_article).count).to eq(0)
    end
  end

  # ACUWT path: course with use_acuwt? set
  context 'for ArticleScopedProgram (ACUWT path)' do
    let(:acuwt_course) { create(:article_scoped_program, flags: { use_acuwt: true }) }
    let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:user) { create(:user, username: 'Ragesoss') }

    before do
      create(:assignment, user_id: user.id, course_id: acuwt_course.id, article_id: 2,
             article_title: 'Assigned')
      manager = TimesliceManager.new(acuwt_course)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
    end

    it 'creates articles_courses and marks ACUWT records as needs_update for new articles' do
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: assigned_article, user:, wiki: enwiki,
             start: acuwt_course.start, end: acuwt_course.start + 1.day,
             revision_count: 3, references_count: 0)

      described_class.new(acuwt_course).run

      expect(acuwt_course.articles_courses.where(article_id: assigned_article.id).count).to eq(1)
      expect(ArticleCourseUserWikiTimeslice
               .find_by(course: acuwt_course, article: assigned_article).needs_update).to eq(true)
      expect(acuwt_course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
    end

    it 'ignores new scoped articles in untracked namespaces' do
      draft_article = create(:article, title: 'Draft article', namespace: 118)
      create(:assignment, user_id: user.id, course_id: acuwt_course.id,
             article_id: draft_article.id, article_title: 'Draft article')
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: draft_article, user:, wiki: enwiki,
             start: acuwt_course.start, end: acuwt_course.start + 1.day,
             revision_count: 2, references_count: 0)

      described_class.new(acuwt_course).run

      expect(acuwt_course.articles_courses.where(article_id: draft_article.id).count).to eq(0)
      expect(ArticleCourseUserWikiTimeslice
               .find_by(course: acuwt_course, article: draft_article).needs_update).to eq(false)
    end

    it 'sets needs_reaggregation and removes old unscoped articles' do
      create(:articles_course, course: acuwt_course, article: assigned_article)
      create(:articles_course, course: acuwt_course, article: random_article)
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: random_article, user:, wiki: enwiki,
             start: acuwt_course.start + 1.day, end: acuwt_course.start + 2.days,
             revision_count: 2, references_count: 0)
      create(:article_course_timeslice, course: acuwt_course, article: random_article,
             start: acuwt_course.start + 1.day)

      described_class.new(acuwt_course).run

      expect(acuwt_course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(1)
      expect(acuwt_course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(acuwt_course.course_wiki_timeslices.find_by(needs_reaggregation: true).start)
        .to eq(acuwt_course.start + 1.day)
      expect(acuwt_course.article_course_timeslices
                         .where(article_id: random_article.id).count).to eq(0)
      expect(acuwt_course.articles_courses.count).to eq(1)
      expect(acuwt_course.articles_courses.where(article_id: random_article).count).to eq(0)
      expect(ArticleCourseUserWikiTimeslice
               .where(course: acuwt_course, article: random_article).count).to eq(1)
    end
  end

  context 'for basic course' do
    before do
      enwiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
      user = create(:user, username: 'Ragesoss')
      create(:assignment, user_id: user.id, course_id: basic_course.id, article_id: 2,
            article_title: 'Assigned')
      manager = TimesliceManager.new(basic_course)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])

      create(:article_course_timeslice, course: basic_course, article: random_article,
            start: basic_course.start + 1.day)
      create(:article_course_timeslice, course: basic_course, article: assigned_article,
            start: basic_course.start)
    end

    it 'returns prematurely' do
      create(:articles_course, course: basic_course, article: assigned_article)
      create(:articles_course, course: basic_course, article: random_article)
      described_class.new(basic_course).run

      expect(basic_course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(basic_course.article_course_timeslices.count).to eq(2)
      expect(basic_course.articles_courses.count).to eq(2)
    end
  end
end
