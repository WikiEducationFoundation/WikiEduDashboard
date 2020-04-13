# frozen_string_literal: true

require 'rails_helper'

describe UpdateCourseStats do
  let(:course) { create(:course, flags: flags) }
  let(:subject) { described_class.new(course) }

  context 'when debugging is not enabled' do
    let(:flags) { nil }

    it 'posts no Sentry logs' do
      expect(Raven).not_to receive(:capture_message)
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
      expect(Raven).to receive(:capture_message).at_least(6).times.and_call_original
      subject
    end
  end

  context 'when there are revisions' do
    let(:course) { create(:course, start: '2018-11-23', end: '2018-11-30') }
    let(:user) { create(:user, username: 'Ragesoss') }

    before do
      course.campaigns << Campaign.first
      JoinCourse.new(course: course, user: user, role: 0)
      VCR.use_cassette 'course_update' do
        subject
      end
    end

    it 'imports average views of edited articles' do
      expect(course.articles.count).to eq(2)
      expect(course.articles.last.average_views).to be > 0
    end

    it 'imports the revisions and their ORES data' do
      expect(course.revisions.count).to eq(2)
      course.revisions.each do |revision|
        expect(revision.features).to have_key('feature.wikitext.revision.ref_tags')
        expect(revision.features_previous).to have_key('feature.wikitext.revision.ref_tags')
      end
    end
  end
end
