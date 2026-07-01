# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe UpdateTimeslicesUntrackedArticle do
  let(:start) { '2021-01-24'.to_datetime }
  let(:course) { create(:course, start:, end: '2021-01-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:updater) { described_class.new(course).run }
  let(:user1) { create(:user, username: 'Ragesoss') }
  let(:user2) { create(:user, username: 'Oleryhlolsson') }
  let(:user3) { create(:user, username: 'erika') }
  let(:manager) { TimesliceManager.new(course) }
  let(:wikidata_article) { create(:article, wiki: wikidata) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: enwiki) }

  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
    # Add two users
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
    JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
    manager.create_timeslices_for_new_course_wiki_records([enwiki])
    # Add articles courses and timeslices manually
    create(:articles_course, course:, article: article1, user_ids: [user1.id])
    create(:articles_course, course:, article: article2, user_ids: [user1.id, user2.id])

    create(:article_course_timeslice, course:, article: article1, start:, user_ids: [user1.id])
    create(:article_course_timeslice, course:, article: article2, start: start + 1.day,
           user_ids: [user1.id, user2.id])
    create(:article_course_timeslice, course:, article: article2, start:, user_ids: [user2.id])
    create(:article_course_timeslice, course:, article: article2, start: start + 2.days,
           user_ids: [user1.id])
  end

  context 'when some article was untracked' do
    before do
      # Untrack article
      ArticlesCourses.find_by(article_id: article2.id).update(tracked: false)
    end

    it 'sets course wiki timeslices as needs_update' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(0)

      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(3)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(3)
    end
  end

  context 'when some article was re-tracked' do
    before do
      # Mark timeslices for article 2 as untracked to simulate article2 is untracked
      ArticleCourseTimeslice.where(course:, article: article2).update(tracked: false)
    end

    it 'sets course wiki timeslices as needs_update' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(3)

      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(3)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(0)
    end
  end

  context 'ACUWT path' do
    let(:acuwt_course) do
      create(:course, title: 'ACUWT course', school: 'WÏNTR', term: 'spring 2021',
             slug: 'WÏNTR/ACUWT_course_(spring_2021)', start:, end: '2021-01-30',
             flags: { use_acuwt: true })
    end
    let(:acuwt_manager) { TimesliceManager.new(acuwt_course) }

    before do
      acuwt_course.campaigns << Campaign.first
      JoinCourse.new(course: acuwt_course, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course: acuwt_course, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      acuwt_manager.create_timeslices_for_new_course_wiki_records([enwiki])
      create(:articles_course, course: acuwt_course, article: article1)
      create(:articles_course, course: acuwt_course, article: article2)
      # ACUWT rows: article1 at start (user1), article2 at start (user1) and start+1.day (user2)
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: article1, user: user1, wiki: enwiki,
             start:, end: start + 1.day)
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: article2, user: user1, wiki: enwiki,
             start:, end: start + 1.day)
      create(:article_course_user_wiki_timeslice,
             course: acuwt_course, article: article2, user: user2, wiki: enwiki,
             start: start + 1.day, end: start + 2.days)
      # ACT rows for both articles
      create(:article_course_timeslice, course: acuwt_course, article: article1, start:)
      create(:article_course_timeslice, course: acuwt_course, article: article2, start:)
      create(:article_course_timeslice, course: acuwt_course, article: article2,
             start: start + 1.day)
      # CUWT rows for the periods covered by article2
      create(:course_user_wiki_timeslice,
             course: acuwt_course, user: user1, wiki: enwiki, start:, end: start + 1.day)
      create(:course_user_wiki_timeslice,
             course: acuwt_course, user: user2, wiki: enwiki,
             start: start + 1.day, end: start + 2.days)
    end

    context 'when an article is untracked' do
      before do
        ArticlesCourses.find_by(course: acuwt_course, article: article2).update(tracked: false)
      end

      it 'sets needs_reaggregation, deletes ACT and CUWT rows, and marks ACUWT as untracked' do
        expect(acuwt_course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(0)
        expect(acuwt_course.article_course_timeslices.count).to eq(3)
        expect(CourseUserWikiTimeslice.where(course: acuwt_course).count).to eq(2)
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: false).count).to eq(0)

        described_class.new(acuwt_course).run

        # CWT marked for reaggregation for the two periods covered by article2's ACUWT rows
        expect(acuwt_course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(2)
        # ACT rows for article2 deleted; article1's row survives
        expect(acuwt_course.article_course_timeslices.count).to eq(1)
        expect(acuwt_course.article_course_timeslices.first.article).to eq(article1)
        # CUWT rows deleted for the affected periods
        expect(CourseUserWikiTimeslice.where(course: acuwt_course).count).to eq(0)
        # ACUWT rows for article2 marked as untracked; article1's row unaffected
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: false).count).to eq(2)
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: true).count).to eq(1)
      end
    end

    context 'when an article is re-tracked' do
      before do
        # Simulate article2 having been previously untracked
        ArticleCourseUserWikiTimeslice.where(course: acuwt_course, article: article2)
                                      .update_all(tracked: false) # rubocop:disable Rails/SkipsModelValidations
      end

      it 'sets needs_reaggregation, deletes ACT and CUWT rows, and marks ACUWT as tracked' do
        expect(acuwt_course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(0)
        expect(acuwt_course.article_course_timeslices.count).to eq(3)
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: false).count).to eq(2)

        described_class.new(acuwt_course).run

        # CWT marked for reaggregation for the two periods covered by article2's ACUWT rows
        expect(acuwt_course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(2)
        # ACT rows for article2 deleted; article1's row survives
        expect(acuwt_course.article_course_timeslices.count).to eq(1)
        # CUWT rows deleted for the affected periods
        expect(CourseUserWikiTimeslice.where(course: acuwt_course).count).to eq(0)
        # All ACUWT rows now tracked
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: false).count).to eq(0)
        expect(ArticleCourseUserWikiTimeslice
                 .where(course: acuwt_course, tracked: true).count).to eq(3)
      end
    end
  end
end
