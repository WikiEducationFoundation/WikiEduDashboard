# frozen_string_literal: true

require 'rails_helper'

describe UpdateCourseWikiTimeslices do
  # Use basic_course to not override the end datetime with end_of_day
  let(:course) do
    create(:basic_course, start: '2018-11-24 00:00:00', end: '2018-11-30 23:55:00', flags:)
  end
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:updater) { described_class.new(course, UpdateDebugger.new(course)) }
  let(:subject) { updater.run(all_time: false) }
  let(:flags) { nil }
  let(:user) { create(:user, username: 'Ragesoss') }

  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
    travel_to Date.new(2018, 12, 1)
    course.campaigns << Campaign.first
    course.wikis << wikidata
    JoinCourse.new(course:, user:, role: 0)
  end

  after do
    travel_back
  end

  context 'when debugging is not enabled' do
    it 'posts no Sentry logs' do
      expect(Sentry).not_to receive(:capture_message)
      processed, reprocessed = subject
      expect(processed).to eq(14)
      expect(reprocessed).to eq(0)
    end
  end

  context 'when :debug_updates flag is set' do
    let(:flags) { { debug_updates: true } }

    it 'posts debug info to Sentry' do
      expect(Sentry).to receive(:capture_message).at_least(:twice).and_call_original
      subject
    end
  end

  context 'when there are revisions' do
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
      expect(article_course.article_course_timeslices.first.first_revision)
        .to eq('2018-11-24 04:49:31')
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
      expect(timeslice.last_mw_rev_datetime).to eq('20181129180841'.to_datetime)
      expect(timeslice.stats).to be_empty

      # For wikidata
      timeslice = course.course_wiki_timeslices.where(wiki: wikidata,
                                                      start: '2018-11-24').first
      expect(timeslice.character_sum).to eq(7867)
      expect(timeslice.references_count).to eq(-2)
      expect(timeslice.revision_count).to eq(27)
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

      # only fails for timeslices with new data
      expect(Sentry).to have_received(:capture_message).exactly(3).times

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
          expect_any_instance_of(CourseRevisionUpdater).to receive(:fetch_data_for_course_wiki)
            .with(wiki, start_time, end_time, only_new: true)
            .once
            .and_call_original
        end
      end

      VCR.use_cassette 'course_update' do
        subject
      end
    end
  end

  context 'when there is no point in importing revisions' do
    before do
      CoursesUsers.find_by(course:, user:).destroy
      # Create timeslices
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records(course.wikis)
      # Set timeslices to reprocess
      course.course_wiki_timeslices.where(wiki: enwiki)
            .first.update(revision_count: 15,
                          last_mw_rev_datetime: '2018-11-24 10:25:00',
                          needs_update: true)
      course.course_wiki_timeslices.where(wiki: wikidata)
            .first.update(revision_count: 15,
                          last_mw_rev_datetime: '2018-11-24 10:25:00',
                          stats: { 'total revisions:': 15 },
                          needs_update: true)
    end

    it 'does not fail and logs no errors' do
      VCR.use_cassette 'course_update' do
        expect(Sentry).not_to receive(:capture_message)
        subject
      end
    end

    it 'cleans old caches' do
      VCR.use_cassette 'course_update' do
        subject
        enwiki_timeslice = course.course_wiki_timeslices.where(wiki: enwiki).first
        expect(enwiki_timeslice.revision_count).to eq(0)
        expect(enwiki_timeslice.needs_update).to eq(false)
        expect(enwiki_timeslice.last_mw_rev_datetime).to eq(nil)
        wikidata_timeslice = course.course_wiki_timeslices.where(wiki: wikidata).first
        expect(wikidata_timeslice.revision_count).to eq(0)
        expect(wikidata_timeslice.needs_update).to eq(false)
        expect(wikidata_timeslice.last_mw_rev_datetime).to eq(nil)
        expect(wikidata_timeslice.stats['total revisions']).to eq(0)
      end
    end
  end

  context 'when course start and end dates are future' do
    before do
      travel_to Date.new(2017, 12, 1)
    end

    after do
      travel_back
    end

    it 'does not fail' do
      subject
      expect(course.course_wiki_timeslices.count).to eq(14)
    end
  end

  context 'when a full update is required' do
    before do
      course.update(needs_update: true)
    end

    it 'sets needs_update to false if update is successful' do
      updater.run(all_time: true)
      expect(course.needs_update).to eq(false)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
    end

    it 'sets needs_update to false even if the update fails' do
      # Stub something to raise an error
      allow_any_instance_of(CourseRevisionUpdater).to receive(:fetch_data_for_course_wiki)
        .and_raise(StandardError, 'simulate failure')

      # Rescue the expected error to prevent spec from failing
      begin
        updater.run(all_time: true)
      rescue StandardError
        expect(course.needs_update).to eq(false)
        expect(course.course_wiki_timeslices.where(needs_update: true).count).to be > 0
      end
    end
  end
end
