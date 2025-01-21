# frozen_string_literal: true

require 'rails_helper'

describe UpdateCourseWikiTimeslices do
  # Use basic_course to not override the end datetime with end_of_day
  let(:course) do
    create(:basic_course, start: '2018-11-24 00:00:00', end: '2018-11-30 23:55:00', flags:)
  end
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:updater) { described_class.new(course) }
  let(:subject) { updater.run(all_time: false) }
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

  context 'when there are revisions' do
    before do
      stub_wiki_validation
      travel_to Date.new(2018, 12, 1)
      course.campaigns << Campaign.first
      # Create course wiki timeslices manually for wikidata
      course.wikis << Wiki.get_or_create(language: nil, project: 'wikidata')
      JoinCourse.new(course:, user:, role: 0)
    end

    it 'updates article course timeslices caches' do
      VCR.use_cassette 'course_update' do
        subject
      end

      # Check caches for mw_page_id 6901525
      article = Article.find_by(mw_page_id: 6901525)
      # The article course exists
      article_course = ArticlesCourses.find_by(article_id: article.id)

      # Article course timeslice record was created for mw_page_id 6901525
      # timeslices for 2018-11-24 was created
      expect(article_course.article_course_timeslices.count).to eq(1)
      expect(article_course.article_course_timeslices.first.start).to eq('2018-11-24')
      # Article course timeslices caches were updated
      expect(article_course.article_course_timeslices.first.character_sum).to eq(427)
      expect(article_course.article_course_timeslices.first.references_count).to eq(-2)
      expect(article_course.article_course_timeslices.first.user_ids).to eq([user.id])
    end

    it 'updates course user wiki timeslices caches' do
      VCR.use_cassette 'course_update' do
        subject
      end

      # Check caches for course user
      course_user = CoursesUsers.find_by(course:, user:)
      # The course user caches were updated
      # All the revisions were done in mainspace = 0,
      # except for one revision in mainspace = 120, which is ommited
      # At least two course user timeslice records were updated

      # Course user timeslices caches were updated
      # For enwiki
      timeslice = course_user.course_user_wiki_timeslices.where(wiki: enwiki,
                                                                start: '2018-11-24').first
      expect(timeslice.character_sum_ms).to eq(46)
      expect(timeslice.character_sum_us).to eq(0)
      expect(timeslice.character_sum_draft).to eq(0)
      expect(timeslice.revision_count).to eq(1)
      expect(timeslice.references_count).to eq(0)

      # For wikidata
      timeslice = course_user.course_user_wiki_timeslices.where(wiki: wikidata,
                                                                start: '2018-11-24').first
      expect(timeslice.character_sum_ms).to eq(7867)
      expect(timeslice.character_sum_us).to eq(0)
      expect(timeslice.character_sum_draft).to eq(0)
      expect(timeslice.revision_count).to eq(27)
      expect(timeslice.references_count).to eq(-2)
    end

    it 'updates course wiki timeslices caches' do
      VCR.use_cassette 'course_update' do
        subject
      end
      # 14 course wiki timeslices records were created: 7 for enwiki and 7 for wikidata
      expect(course.course_wiki_timeslices.count).to eq(14)

      # Course wiki timeslices caches were updated
      # For enwiki
      timeslice = course.course_wiki_timeslices.where(wiki: enwiki,
                                                      start: '2018-11-29').first
      expect(timeslice.character_sum).to eq(78)
      expect(timeslice.references_count).to eq(0)
      expect(timeslice.revision_count).to eq(1)
      expect(timeslice.upload_count).to eq(0)
      expect(timeslice.uploads_in_use_count).to eq(0)
      expect(timeslice.upload_usages_count).to eq(0)
      expect(timeslice.last_mw_rev_datetime).to eq('20181129180841'.to_datetime)
      expect(timeslice.stats).to be_empty

      # For wikidata
      timeslice = course.course_wiki_timeslices.where(wiki: wikidata,
                                                      start: '2018-11-24').first
      expect(timeslice.character_sum).to eq(7867)
      expect(timeslice.references_count).to eq(-2)
      expect(timeslice.revision_count).to eq(27)
      expect(timeslice.upload_count).to eq(0)
      expect(timeslice.uploads_in_use_count).to eq(0)
      expect(timeslice.upload_usages_count).to eq(0)
      expect(timeslice.last_mw_rev_datetime).to eq('20181124045740'.to_datetime)
      expect(timeslice.stats['references removed']).to eq(2)
    end

    it 'rolls back the updates if something goes wrong' do
      allow(Sentry).to receive(:capture_message)
      # Stub out update_course_wiki_timeslices to raise an error
      allow(CourseWikiTimeslice).to receive(:update_course_wiki_timeslices)
        .and_raise(StandardError, 'Simulated failure')

      VCR.use_cassette 'course_update' do
        subject
      end

      expect(Sentry).to have_received(:capture_message).exactly(14).times

      # last_mw_rev_datetime wasn't updated
      timeslice = course.course_wiki_timeslices.where(wiki: enwiki, start: '2018-11-29').first

      expect(timeslice.last_mw_rev_datetime).to be_nil
    end

    it 'fetches revisions up to end date' do
      expected_dates = [
        %w[20181124000000 20181124235959],
        %w[20181125000000 20181125235959],
        %w[20181126000000 20181126235959],
        %w[20181127000000 20181127235959],
        %w[20181128000000 20181128235959],
        %w[20181129000000 20181129235959],
        %w[20181130000000 20181130235500]
      ]

      expected_wikis = [enwiki, wikidata]

      expected_dates.each do |start_time, end_time|
        expected_wikis.each do |wiki|
          expect(CourseRevisionUpdater).to receive(:fetch_revisions_and_scores_for_wiki)
            .with(course, wiki, start_time, end_time, update_service: updater)
            .once
        end
      end

      VCR.use_cassette 'course_update' do
        subject
      end
    end
  end

  context 'sentry course update error tracking' do
    let(:flags) { { debug_updates: true } }
    let(:user) { create(:user, username: 'Ragesoss') }

    before do
      travel_to Date.new(2018, 11, 28)
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user:, role: 0)
    end

    it 'tracks update errors properly in Replica' do
      allow(Sentry).to receive(:capture_exception)

      # Raising errors only in Replica
      stub_request(:any, %r{https://replica-revision-tools.wmcloud.org/.*}).to_raise(Errno::ECONNREFUSED)
      VCR.use_cassette 'course_update/replica' do
        subject
      end
      sentry_tag_uuid = updater.sentry_tag_uuid

      # Checking whether Sentry receives correct error and tags as arguments
      expect(Sentry).to have_received(:capture_exception).exactly(5).times.with(
        Errno::ECONNREFUSED, anything
      )
      expect(Sentry).to have_received(:capture_exception)
        .exactly(5).times.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                    course: course.slug })
    end

    it 'tracks update errors properly in LiftWing' do
      allow(Sentry).to receive(:capture_exception)

      # Raising errors only in LiftWing
      stub_request(:any, %r{https://api.wikimedia.org/service/lw.*}).to_raise(Faraday::ConnectionFailed)
      VCR.use_cassette 'course_update/lift_wing_api' do
        subject
      end
      sentry_tag_uuid = updater.sentry_tag_uuid

      # Checking whether Sentry receives correct error and tags as arguments
      expect(Sentry).to have_received(:capture_exception)
        .exactly(2).times.with(Faraday::ConnectionFailed, anything)
      expect(Sentry).to have_received(:capture_exception)
        .exactly(2).times.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                                course: course.slug })
      # The timeslice for the revision with score errors is marked as 'needs update'
      expect(course.course_wiki_timeslices.find_by(start: '2018-11-24').needs_update).to eq(true)
    end
  end
end
