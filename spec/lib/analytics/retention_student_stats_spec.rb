# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_student_stats"

# The metrics themselves are covered end to end by the CSV builder spec; this
# covers what the report card additionally relies on.
describe RetentionStudentStats do
  include RetentionApiStubs

  let(:wiki) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }
  let(:student) { create(:user, username: 'user1') }

  before do
    allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists)
    course.wikis = [wiki]
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  describe '.stage' do
    it 'is 0 until a day after the course ends' do
      expect(described_class.stage(course, course.end - 1.day)).to eq(0)
      expect(described_class.stage(course, course.end + 23.hours)).to eq(0)
    end

    it 'is 1 once during-course sessions are final' do
      expect(described_class.stage(course, course.end + 1.day)).to eq(1)
      expect(described_class.stage(course, course.end + 30.days)).to eq(1)
    end

    it 'is 2 once the 30-day return window has closed' do
      expect(described_class.stage(course, course.end + 31.days)).to eq(2)
    end

    it 'is final once the 60-90-day survival window has closed' do
      expect(described_class.stage(course, course.end + 91.days)).to eq(3)
      expect(described_class.stage(course, course.end + 5.years))
        .to eq(described_class::FINAL_STAGE)
    end
  end

  describe '#stats' do
    it 'identifies each student and reports the numeric prior edit count' do
      stub_wiki(wiki, { 'user1' => [course.end - 1.day] }, { 'user1' => 12 })
      stats = described_class.new(course).stats
      expect(stats.size).to eq(1)
      expect(stats.first).to include(user_id: student.id, username: 'user1', sessions_during: 1,
                                     prior_edit_count: 12, prior_edits: '12', long_term: false,
                                     returning: false, prior_courses: 0)
    end

    context 'when fetching the edit timeline' do
      let(:queries) { [] }

      before do
        api = instance_double(WikiApi)
        allow(WikiApi).to receive(:new).with(wiki).and_return(api)
        allow(api).to receive(:query) do |params|
          queries << params
          response_for([])
        end
      end

      it 'stops at the end of the survival window rather than the present' do
        described_class.new(course)
        timeline_query = queries.find { |q| q.key?(:ucend) }
        expect(timeline_query[:ucstart]).to eq((course.end + 90.days).strftime('%Y%m%d%H%M%S'))
        expect(timeline_query[:ucend]).to eq(course.start.strftime('%Y%m%d%H%M%S'))
      end

      context 'while the survival window is still open' do
        let(:course) { create(:course, start: 40.days.ago, end: 10.days.ago) }

        it 'fetches through the present' do
          now = Time.zone.now
          described_class.new(course, now:)
          timeline_query = queries.find { |q| q.key?(:ucend) }
          expect(timeline_query[:ucstart]).to eq(now.strftime('%Y%m%d%H%M%S'))
        end
      end
    end
  end
end
