# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe UpdateTimeslicesCourseUser do
  before { stub_const('TimesliceManager::TIMESLICE_DURATION', 86400) }

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
  let(:update_logs) do
    { 'update_logs' => { 1 => { 'start_time' => 3.minutes.ago,
      'end_time' => 2.minutes.ago } } }
  end

  context 'when some course user was removed' do
    before do
      stub_wiki_validation
      # Add two users
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      # Add articles courses and timeslices manually
      create(:articles_course, course:, article: article1, user_ids: [user1.id])
      create(:articles_course, course:, article: article2, user_ids: [user1.id, user2.id])

      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki)
      create(:course_user_wiki_timeslice, course:, user: user2, wiki: enwiki)

      create(:article_course_timeslice, course:, article: article1, start:, user_ids: [user1.id])
      create(:article_course_timeslice, course:, article: article2, start:,
      user_ids: [user1.id, user2.id])
      create(:article_course_timeslice, course:, article: article2, start: start + 1.day,
      user_ids: [user2.id])
      create(:article_course_timeslice, course:, article: article2, start: start + 2.days,
      user_ids: [user1.id])
      # Delete course user
      CoursesUsers.find_by(course:, user: user1).delete
    end

    it 'returns immediately if no previous update' do
      # TODO: improve this spec because it doesn't make a lot of sense
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run

      # Nothing changed
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)
    end

    it 'removes course user wiki timeslices and updates course wiki timeslices' do
      # Set previous update
      course.flags = update_logs
      course.save

      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end

  context 'when some course user was added' do
    before do
      stub_wiki_validation
      # Add one user and create timeslices
      course.campaigns << Campaign.first
      course_user = CoursesUsers.create(user: user1, course:,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
      course_user.update(created_at: 2.hours.ago)

      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki)

      # add the new user
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course:, user: user3, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'returns immediately if no previous update' do
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(1)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      # No timeslice was marked as needs_update
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'updates course wiki timeslices if previous update' do
      course.flags = update_logs
      course.save
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(1)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There are two student users and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(6)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'doesnt update course wiki timeslices twice' do
      course.flags = update_logs
      course.save

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(6)

      # Reset needs_update to false
      course.course_wiki_timeslices.update(needs_update: false)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # Timeslices weren't set to reprocess again
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
    end
  end

  # ACUWT path: course with use_acuwt? set. Instead of marking timeslices as needs_update
  # for a full re-fetch, these paths operate on ArticleCourseUserWikiTimeslice rows and
  # mark the affected CourseWikiTimeslices as needs_reaggregation.
  context 'when some course user was removed (ACUWT path)' do
    before do
      stub_wiki_validation
      course.flags = { use_acuwt: true }.merge(update_logs)
      course.save
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      # Keep both users out of the "newly added" set so the add path is a no-op
      course.courses_users.update_all(created_at: 2.hours.ago) # rubocop:disable Rails/SkipsModelValidations
      manager.create_timeslices_for_new_course_wiki_records([enwiki])

      # CUWT rows for both users in the first period
      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki, start:)
      create(:course_user_wiki_timeslice, course:, user: user2, wiki: enwiki, start:)
      # ACT rows for both articles in the first period
      create(:article_course_timeslice, course:, article: article1, start:, user_ids: [user1.id])
      create(:article_course_timeslice, course:, article: article2, start:, user_ids: [user2.id])
      # ACUWT rows: article1/user1 and article2/user2, both in the first period
      create(:article_course_user_wiki_timeslice, course:, article: article1, user: user1,
             wiki: enwiki, start:, end: start + 1.day, revision_count: 1)
      create(:article_course_user_wiki_timeslice, course:, article: article2, user: user2,
             wiki: enwiki, start:, end: start + 1.day, revision_count: 1)
      # Remove user1 from the course; their CUWT row makes them a "processed" (now-deleted) user
      CoursesUsers.find_by(course:, user: user1).delete
    end

    it 'deletes the removed user ACUWT rows and marks affected timeslices for reaggregation' do
      described_class.new(course).run

      # The removed user's ACUWT rows are gone; the remaining user's are untouched
      expect(ArticleCourseUserWikiTimeslice.where(course:, user: user1).count).to eq(0)
      expect(ArticleCourseUserWikiTimeslice.where(course:, user: user2).count).to eq(1)
      # The CWT for the affected period is flagged for reaggregation (not needs_update)
      expect(course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(1)
      expect(course.course_wiki_timeslices.find_by(needs_reaggregation: true).start).to eq(start)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      # ACT for the removed user's article/period is deleted; the other article's ACT remains
      expect(course.article_course_timeslices.where(article: article1).count).to eq(0)
      expect(course.article_course_timeslices.where(article: article2).count).to eq(1)
      # CUWT rows for the affected (wiki, period) are deleted for all users
      # (they are rebuilt during the reaggregation pass)
      expect(course.course_user_wiki_timeslices.where(wiki: enwiki, start:).count).to eq(0)
    end
  end

  context 'when some course user was added (ACUWT path)' do
    before do
      stub_wiki_validation
      course.flags = { use_acuwt: true }.merge(update_logs)
      course.save
      course.campaigns << Campaign.first
      # Existing, already-processed user
      course_user = CoursesUsers.create(user: user1, course:,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
      course_user.update(created_at: 2.hours.ago)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki, start:)
      # Add a new student (created_at defaults to now, i.e. after the last update start)
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'creates ACUWT rows for the new user and marks the period for reaggregation' do
      revision = build(:revision_on_memory,
                       article_id: article1.id, user_id: user2.id, wiki_id: enwiki.id,
                       mw_rev_id: 12_345, mw_page_id: article1.mw_page_id,
                       date: start + 1.hour, scoped: true, new_article: false)
      # Revisions are fetched per timeslice; only the first timeslice has a revision
      allow_any_instance_of(CourseRevisionUpdater)
        .to receive(:fetch_revisions_for_new_users) do |_updater, _wiki, _users, ts_start, _ts_end|
        ts_start == start.strftime('%Y%m%d%H%M%S') ? [revision] : []
      end

      expect(ArticleCourseUserWikiTimeslice.where(course:, user: user2).count).to eq(0)

      described_class.new(course).run

      # An ACUWT row was created for the new user, in the period the revision falls in
      acuwt = ArticleCourseUserWikiTimeslice.where(course:, user: user2)
      expect(acuwt.count).to eq(1)
      expect(acuwt.first.start).to eq(start)
      expect(acuwt.first.revision_count).to eq(1)
      # The CWT for that period is flagged for reaggregation
      expect(course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(1)
      expect(course.course_wiki_timeslices.find_by(needs_reaggregation: true).start).to eq(start)
    end

    it 'fetches revisions once per course wiki timeslice' do
      fetch_calls = []
      allow_any_instance_of(Replica)
        .to receive(:get_revisions) do |_replica, _users, ts_start, ts_end|
        fetch_calls << [ts_start, ts_end]
        {}
      end

      described_class.new(course).run

      # One fetch per timeslice, bounded to the timeslice period. The end bound is
      # inclusive for Replica, so it's one second before the next timeslice start.
      expect(fetch_calls.count).to eq(7)
      expect(fetch_calls.min).to eq([start.strftime('%Y%m%d%H%M%S'),
                                     (start + 1.day - 1.second).strftime('%Y%m%d%H%M%S')])
    end

    it 'marks the new user as processed so an interrupted update does not redo them' do
      allow_any_instance_of(CourseRevisionUpdater)
        .to receive(:fetch_revisions_for_new_users).and_return([])

      expect(CoursesUsers.find_by(course:, user: user2).created_at)
        .to be >= course.last_update_start_time

      described_class.new(course).run

      expect(CoursesUsers.find_by(course:, user: user2).created_at)
        .to be < course.last_update_start_time
    end

    it 'continues with remaining users when processing one user fails' do
      JoinCourse.new(course:, user: user3, role: CoursesUsers::Roles::STUDENT_ROLE)
      allow_any_instance_of(CourseRevisionUpdater)
        .to receive(:fetch_revisions_for_new_users) do |_updater, _wiki, users, _ts_start, _ts_end|
        raise StandardError, 'Replica timeout' if users.first.id == user2.id
        []
      end
      expect(Sentry).to receive(:capture_message)

      described_class.new(course).run

      # The failed user is still considered new, so the next update retries them;
      # the successfully processed user is not redone
      expect(CoursesUsers.find_by(course:, user: user2).created_at)
        .to be >= course.last_update_start_time
      expect(CoursesUsers.find_by(course:, user: user3).created_at)
        .to be < course.last_update_start_time
    end
  end
end
