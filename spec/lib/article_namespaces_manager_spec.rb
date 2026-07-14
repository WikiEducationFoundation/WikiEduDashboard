# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_namespaces_manager"
require "#{Rails.root}/lib/timeslice_manager"

describe ArticleNamespacesManager do
  let(:course) { create(:course, start: 1.year.ago, end: 1.year.from_now) }
  let(:wiki) { course.home_wiki }
  let(:moved_to_mainspace) { 2.weeks.ago }
  let(:first_revision) { 2.months.ago }
  let(:mainspace_article) { create(:article, namespace: 0, updated_at: moved_to_mainspace) }
  let(:subject) { described_class.new(course) }

  context 'when an article moved from userspace to mainspace' do
    before do
      create(:articles_course, course:, article_id: mainspace_article.id,
             created_at: moved_to_mainspace)
      create(:course_wiki_timeslice, course:, wiki:, start: first_revision.beginning_of_day)
      create(:course_wiki_timeslice, course:, wiki:, start: moved_to_mainspace.beginning_of_day)
      create(:article_course_timeslice, course:, article_id: mainspace_article.id,
              start: first_revision.beginning_of_day, created_at: first_revision.beginning_of_day)
      create(:article_course_timeslice, course:, article_id: mainspace_article.id,
              start: moved_to_mainspace.beginning_of_day,
              created_at: moved_to_mainspace.beginning_of_day)
    end

    it 'resets timeslices for article' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(ArticlesCourses.where(article_id: mainspace_article.id).count).to eq(1)
      expect(ArticleCourseTimeslice.where(article_id: mainspace_article.id).count).to eq(2)
      subject
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(ArticlesCourses.where(article_id: mainspace_article.id)).to be_empty
      expect(ArticleCourseTimeslice.where(article_id: mainspace_article.id).count).to eq(0)
    end

    it 'logs the retracked article to Sentry' do
      allow(Sentry).to receive(:capture_message)
      subject

      expect(Sentry).to have_received(:capture_message)
        .with('Article retracked', level: 'info',
              extra: { course_slug: course.slug, course_id: course.id,
                       reason: 'moved_to_mainspace',
                       article_ids: [mainspace_article.id] })
    end

    # For ACUWT courses, this case is detected when the articles_courses record is
    # created instead (see ArticlesCourses.update_from_course_revisions).
    context 'when the course uses ACUWT' do
      before do
        course.add_flag(key: :use_acuwt)
      end

      it 'does not reset the article' do
        subject
        expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
        expect(ArticlesCourses.where(article_id: mainspace_article.id).count).to eq(1)
        expect(ArticleCourseTimeslice.where(article_id: mainspace_article.id).count).to eq(2)
      end
    end
  end

  context 'when the tracked status of articles changed' do
    let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
    let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
    let(:start) { '2024-01-01'.to_datetime }
    let(:course) { create(:course, start:, end: '2024-04-20') }
    let(:manager) { TimesliceManager.new(course) }
    let(:article1) { create(:article, wiki: enwiki) }
    let(:article2) { create(:article, wiki: wikidata) }
    let(:article3) { create(:article, wiki: wikidata, namespace: 3) }
    let(:article4) { create(:article, wiki: wikidata) }

    before do
      stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
      stub_wiki_validation
      create(:articles_course, course:, article: article1)
      create(:articles_course, course:, article: article2)
      create(:articles_course, course:, article: article3)

      create(:article_course_timeslice, course:, article: article1, start: '2024-04-11',
             end: '2024-04-12')

      create(:article_course_timeslice, course:, article: article2, start:, end: start + 1.day)
      create(:article_course_timeslice, course:, article: article3, start: '2024-01-11',
             end: '2024-01-12')
      create(:article_course_timeslice, course:, article: article4, start: '2024-03-15',
             end: '2024-03-16')

      manager.create_timeslices_for_new_course_wiki_records([enwiki, wikidata])
      article1.update(deleted: true)
      course.wikis << wikidata
    end

    it 'reset articles for untracked articles' do
      described_class.new(course)

      expect(course.article_course_timeslices.where(article: article3)).to be_empty
      expect(course.articles_courses.where(article: article3)).to be_empty
      course_wiki_timeslice = course.course_wiki_timeslices.find_by(wiki: wikidata,
                                                                    start: '2024-01-11')
      expect(course_wiki_timeslice.needs_update).to eq(true)
    end

    it 'reset articles for deleted articles when statuses were synced' do
      described_class.new(course, statuses_synced: true)

      expect(course.article_course_timeslices.where(article: article1)).to be_empty
      expect(course.articles_courses.where(article: article1)).to be_empty
      course_wiki_timeslice = course.course_wiki_timeslices.find_by(wiki: enwiki,
                                                                    start: '2024-04-11')
      expect(course_wiki_timeslice.needs_update).to eq(true)
    end

    it 'reset articles for undeleted or retracked articles when statuses were synced' do
      described_class.new(course, statuses_synced: true)

      expect(course.article_course_timeslices.where(article: article4)).to be_empty
      course_wiki_timeslice = course.course_wiki_timeslices.find_by(wiki: wikidata,
                                                                    start: '2024-03-15')
      expect(course_wiki_timeslice.needs_update).to eq(true)
    end

    it 'does not reset deleted or retracked articles when statuses were not synced' do
      described_class.new(course)

      expect(course.article_course_timeslices.where(article: article1)).not_to be_empty
      expect(course.article_course_timeslices.where(article: article4)).not_to be_empty
    end

    it 'logs untracked articles to Sentry' do
      allow(Sentry).to receive(:capture_message)
      described_class.new(course)

      expect(Sentry).to have_received(:capture_message)
        .with('Article untracked', level: 'info',
              extra: { course_slug: course.slug, course_id: course.id,
                       reason: 'moved_to_untracked_namespace',
                       article_ids: [article3.id] })
    end

    it 'logs deleted articles to Sentry when statuses were synced' do
      allow(Sentry).to receive(:capture_message)
      described_class.new(course, statuses_synced: true)

      expect(Sentry).to have_received(:capture_message)
        .with('Article untracked', level: 'info',
              extra: { course_slug: course.slug, course_id: course.id,
                       reason: 'deleted',
                       article_ids: [article1.id] })
    end

    it 'logs retracked articles to Sentry when statuses were synced' do
      allow(Sentry).to receive(:capture_message)
      described_class.new(course, statuses_synced: true)

      expect(Sentry).to have_received(:capture_message)
        .with('Article retracked', level: 'info',
              extra: { course_slug: course.slug, course_id: course.id,
                       reason: 'undeleted_or_retracked',
                       article_ids: [article4.id] })
    end

    it 'does not reset undeleted or retracked articles for only-scoped-articles courses' do
      allow(course).to receive(:only_scoped_articles_course?).and_return(true)
      described_class.new(course, statuses_synced: true)

      expect(course.article_course_timeslices.where(article: article4)).not_to be_empty
    end
  end
end
