# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe UpdateCourseStats do
  before { stub_const('TimesliceManager::TIMESLICE_DURATION', 86400) }

  let(:course) { create(:course, start: '2018-11-24', end: '2018-11-30', flags:) }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:subject) { described_class.new(course) }
  let(:flags) { nil }
  let(:user) { create(:user, username: 'Ragesoss') }

  context 'when debugging is not enabled' do
    it 'posts no Sentry logs' do
      expect(Sentry).not_to receive(:capture_message)
      subject
    end
  end

  context 'when :debug_updates flag is set' do
    let(:flags) { { debug_updates: true } }

    it 'posts debug info to Sentry' do
      expect(Sentry).to receive(:capture_message).at_least(6).times.and_call_original
      subject
    end
  end

  context 'when needs_update course flag is set' do
    before do
      course.update(needs_update: true)
    end

    it 'makes a full update' do
      expect_any_instance_of(UpdateCourseWikiTimeslices).to receive(:run).with(all_time: true)
                                                                         .and_call_original
      subject
      expect(course.needs_update).to eq(false)
    end
  end

  context 'when there are revisions' do
    before do
      stub_wiki_validation
      travel_to Date.new(2018, 12, 1)
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user:, role: 0)
      # Create course wiki timeslices manually for wikidata
      course.wikis << Wiki.get_or_create(language: nil, project: 'wikidata')
    end

    after do
      travel_back
    end

    it 'does not import average views of edited articles after the first update' do
      VCR.use_cassette 'course_update' do
        subject
      end

      article = Article.find_by(mw_page_id: 1786948)
      article_course = ArticlesCourses.find_by(article_id: article.id)
      expect(article_course.average_views).to be_nil
      expect(article_course.average_views_updated_at).to be_nil
      expect(article_course.first_revision).to eq('2018-11-29 18:08:41'.to_datetime)
    end

    it 'updates article course caches' do
      VCR.use_cassette 'course_update' do
        subject
      end

      # Check caches for mw_page_id 6901525
      article = Article.find_by(mw_page_id: 6901525)
      # The article course exists
      article_course = ArticlesCourses.find_by(article_id: article.id)
      # The article course caches were updated
      expect(article_course.character_sum).to eq(427)
      expect(article_course.references_count).to eq(-2)
      expect(article_course.user_ids).to eq([user.id])
      expect(article_course.view_count).to eq(0)
      expect(article_course.first_revision).to eq('2018-11-24 04:49:31'.to_datetime)
    end

    it 'updates course user caches' do
      VCR.use_cassette 'course_update' do
        subject
      end

      # Check caches for course user
      course_user = CoursesUsers.find_by(course:, user:)
      # The course user caches were updated
      # All the revisions were done in mainspace = 0,
      # except for one revision in mainspace = 120, which is ommited
      expect(course_user.character_sum_ms).to eq(7991)
      expect(course_user.character_sum_us).to eq(0)
      expect(course_user.character_sum_draft).to eq(0)
      expect(course_user.references_count).to eq(-2)
      expect(course_user.revision_count).to eq(29)
      expect(course_user.recent_revisions).to eq(29)
      expect(course_user.total_uploads).to eq(0)
    end

    it 'updates course caches' do
      VCR.use_cassette 'course_update' do
        subject
      end

      # Check caches for course
      # Course caches were updated
      expect(course.character_sum).to eq(7991)
      expect(course.references_count).to eq(-2)
      expect(course.revision_count).to eq(29)
      # TODO: view_sum is miscalculated due to a DISTINCT. See issue #5911
      # FIX ME: view_sum is not updated after the first update
      expect(course.view_sum).to eq(0)
      expect(course.user_count).to eq(1)
      expect(course.trained_count).to eq(1)
      expect(course.recent_revision_count).to eq(29)
      expect(course.article_count).to eq(14)
      expect(course.new_article_count).to eq(3)
      expect(course.upload_count).to eq(0)
      expect(course.uploads_in_use_count).to eq(0)
      expect(course.upload_usages_count).to eq(0)
    end

    it 'rolls back the updates if something goes wrong' do
      allow(Sentry).to receive(:capture_message)
      # Stub out update_all_caches_from_timeslices to raise an error
      allow(CoursesUsers).to receive(:update_all_caches_from_timeslices)
        .and_raise(StandardError, 'Simulated failure')

      VCR.use_cassette 'course_update' do
        subject
      end

      expect(Sentry).to have_received(:capture_message)

      # Check caches for mw_page_id 6901525
      article = Article.find_by(mw_page_id: 6901525)
      # The article course exists
      article_course = ArticlesCourses.find_by(article_id: article.id)
      # The article course caches weren't updated
      expect(article_course.character_sum).to eq(0)
    end
  end

  context 'sentry course update error tracking' do
    let(:flags) { { debug_updates: true } }
    let(:user) { create(:user, username: 'Ragesoss') }
    let(:date) { Date.new(2018, 11, 28) }

    before do
      travel_to date
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user:, role: 0)
    end

    after do
      travel_back
    end

    it 'tracks update errors properly in Replica' do
      allow(Sentry).to receive(:capture_exception)

      # Raising errors only in Replica
      stub_request(:any, %r{https://replica-revision-tools.wmcloud.org/.*}).to_raise(Errno::ECONNREFUSED)
      VCR.use_cassette 'course_update/replica' do
        subject
      end
      sentry_tag_uuid = subject.sentry_tag_uuid
      # one error for each timeslice that tried to update
      expect(course.flags['update_logs'][1]['error_count']).to eq 5
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid
    end

    it 'tracks update errors properly in LiftWing' do
      allow(Sentry).to receive(:capture_exception)

      # Raising errors only in LiftWing
      stub_request(:any, %r{https://api.wikimedia.org/service/lw.*}).to_raise(Faraday::ConnectionFailed)
      VCR.use_cassette 'course_update/lift_wing_api' do
        subject
      end
      sentry_tag_uuid = subject.sentry_tag_uuid
      expect(course.flags['update_logs'][1]['error_count']).to eq 2
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid
    end

    it 'tracks update errors properly in WikiApi' do
      allow(Sentry).to receive(:capture_exception)
      allow_any_instance_of(described_class).to receive(:update_article_status).and_return(nil)

      # Raising errors only in WikiApi
      allow_any_instance_of(MediawikiApi::Client).to receive(:send)
        .and_raise(MediawikiApi::ApiError)
      VCR.use_cassette 'course_update/wiki_api' do
        subject
      end
      sentry_tag_uuid = subject.sentry_tag_uuid
      expect(course.flags['update_logs'][1]['error_count']).to be_positive
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid

      # Checking whether Sentry receives correct error and tags as arguments
      expect(Sentry).to have_received(:capture_exception)
        .at_least(2).times.with(MediawikiApi::ApiError, anything)
      expect(Sentry).to have_received(:capture_exception)
        .at_least(1).times.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                                course: course.slug })
    end

    it 'updates unfinished update log flag if the process crashes midway' do
      expect(course.flags['unfinished_update_logs']).to be_nil
      # Stub import_uploads to raise an error
      allow_any_instance_of(described_class).to receive(:import_uploads)
        .and_raise(StandardError, 'simulate failure')

      # Rescue the expected error to prevent spec from failing
      begin
        described_class.new(course)
      rescue StandardError
        expect(course.flags['unfinished_update_logs'][1]['start_time']).to eq(date)
      end
    end

    context 'when a Programs & Events Dashboard course has a potentially long update time' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 1.year.from_now,
                        flags: { longest_update: 1.hour.to_i })
      end

      before do
        allow(Features).to receive(:wiki_ed?).and_return(false)
      end

      it 'skips article status updates' do
        expect_any_instance_of(described_class).not_to receive(:update_article_status)
        subject
      end
    end

    context 'when course is ArticleScopedProgram type' do
      let(:course) do
        create(:article_scoped_program, start: 1.day.ago, end: 1.year.from_now)
      end

      it 'skips article status updates' do
        expect_any_instance_of(described_class).not_to receive(:update_article_status)
        subject
      end
    end

    context 'when course is VistingScholarship type' do
      let(:course) do
        create(:visiting_scholarship, start: 1.day.ago, end: 1.year.from_now)
      end

      it 'skips article status updates' do
        expect_any_instance_of(described_class).not_to receive(:update_article_status)
        subject
      end
    end
  end
end
