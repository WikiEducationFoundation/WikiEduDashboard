# frozen_string_literal: true
require 'rails_helper'
describe UpdateCourseStats do
  let(:course) { create(:course, flags:) }
  let(:subject) { described_class.new(course) }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

  context 'when debugging is not enabled' do
    let(:flags) { nil }

    it 'posts no Sentry logs' do
      expect(Sentry).not_to receive(:capture_message)
      subject
    end
  end

  context 'when the course has :needs_update set "true"' do
    let(:course) { create(:course, needs_update: true) }

    it 'updates it to "false"' do
      subject
      expect(course.reload.needs_update).to eq(false)
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
    let(:course) { create(:course, start: '2018-11-23', end: '2018-11-30') }
    let(:user) { create(:user, username: 'Ragesoss') }

    before do
      stub_wiki_validation
      course.campaigns << Campaign.first
      course.wikis << Wiki.get_or_create(language: nil, project: 'wikidata')
      JoinCourse.new(course:, user:, role: 0)
      VCR.use_cassette 'course_update' do
        subject
      end
    end

    it 'imports average views of edited articles' do
      # two en.wiki articles plus many wikidata items
      expect(course.articles.where(wiki: enwiki).count).to eq(2)
      expect(course.articles.where(wiki: wikidata).count).to eq(25)
      expect(course.articles.where(wiki: enwiki).last.average_views).to be > 0
    end

    it 'imports the revisions and their ORES data' do
      pending 'This fails occassionally for unknown reasons.'
      # two en.wiki edits plus many wikidata edits
      expect(course.revisions.where(wiki: enwiki).count).to eq(2)
      expect(course.revisions.where(wiki: wikidata).count).to eq(40)
      course.revisions.where(wiki_id: enwiki).each do |revision|
        expect(revision.features).to have_key('feature.wikitext.revision.ref_tags')
        expect(revision.features_previous).to have_key('feature.wikitext.revision.ref_tags')
      end
      pass_pending_spec
    end
  end

  context 'sentry course update error tracking' do
    let(:flags) { { debug_updates: true } }
    let(:user) { create(:user, username: 'Ragesoss') }

    before do
      create(:courses_user, course_id: course.id, user_id: user.id)
    end

    it 'tracks update errors properly in Replica' do
      allow(Sentry).to receive(:capture_exception)
      # Raising errors only in Replica
      stub_request(:any, %r{https://dashboard-replica-endpoint.wmcloud.org/.*}).to_raise(Errno::ECONNREFUSED)
      VCR.use_cassette 'course_update/replica' do
        subject
      end
      sentry_tag_uuid = subject.sentry_tag_uuid
      expect(course.flags['update_logs'][1]['error_count']).to eq 0
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid

      expect(Sentry).to have_received(:capture_exception).once.with(Errno::ECONNREFUSED, anything)
      expect(Sentry).to have_received(:capture_exception)
        .once.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                    course: course.slug })
    end

    it 'tracks update errors properly in LiftWing' do
      allow(Sentry).to receive(:capture_exception)
      # Raising errors only in LiftWing
      stub_request(:any, %r{https://api.wikimedia.org/service/lw.*}).to_raise(Faraday::ConnectionFailed)
      VCR.use_cassette 'course_update/lift_wing_api' do
        subject
      end
      sentry_tag_uuid = subject.sentry_tag_uuid
      error_count = subject.error_count
      expect(course.flags['update_logs'][1]['error_count']).to eq error_count
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid

      # Checking whether Sentry receives correct error and tags as arguments
      expect(Sentry).to have_received(:capture_exception)
        .exactly(8).times.with(Faraday::ConnectionFailed, anything)
      expect(Sentry).to have_received(:capture_exception)
        .exactly(8).times.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                                course: course.slug })
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
      expect(course.flags['update_logs'][1]['error_count']).to be >= 0
      expect(course.flags['update_logs'][1]['sentry_tag_uuid']).to eq sentry_tag_uuid

      # Checking whether Sentry receives correct error and tags as arguments
      expect(Sentry).to have_received(:capture_exception)
        .at_least(5).times.with(MediawikiApi::ApiError, anything)
      expect(Sentry).to have_received(:capture_exception)
        .at_least(5).times.with anything, hash_including(tags: { update_service_id: sentry_tag_uuid,
                                                                course: course.slug })
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
  end
end
