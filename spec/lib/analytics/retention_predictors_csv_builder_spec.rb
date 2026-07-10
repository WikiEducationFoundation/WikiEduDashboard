# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_predictors_csv_builder"

describe RetentionPredictorsCsvBuilder do
  let(:wiki1) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:wiki2) { Wiki.find_or_create_by(language: 'es', project: 'wikipedia') }
  let(:user1) { create(:user, username: 'user1') }
  let(:user2) { create(:user, username: 'user2') }
  let(:course_wikis) { [wiki1] }

  before do
    # The Wiki model validates against the live API on create; skip that here.
    allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists)
    course.wikis = course_wikis
    create(:courses_user, course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  # Builds a stub MediaWiki API response object for a list of edit Times.
  def response_for(times, continue: nil)
    contribs = times.map { |t| { 'timestamp' => t.utc.strftime('%Y-%m-%dT%H:%M:%SZ') } }
    instance_double(MediawikiApi::Response).tap do |response|
      allow(response).to receive(:data).and_return('usercontribs' => contribs)
      allow(response).to receive(:[]).with('continue').and_return(continue)
    end
  end

  # Stubs WikiApi.new(wiki) so that usercontribs queries return the given
  # per-username timestamps. `contribs_by_user` maps username => [Time, ...].
  def stub_wiki(wiki, contribs_by_user)
    api = instance_double(WikiApi)
    allow(WikiApi).to receive(:new).with(wiki).and_return(api)
    allow(api).to receive(:query) do |params|
      response_for(contribs_by_user.fetch(params[:ucuser], []))
    end
  end

  let(:table) { CSV.parse(described_class.new(course).generate_csv) }

  # value cell of a "label,value" summary row
  def summary_value(label)
    table.find { |row| row[0] == label }&.at(1)
  end

  # full per-student detail row, keyed by username
  def detail_row(username)
    table.find { |row| row[0] == username }
  end

  describe '#generate_csv' do
    context 'when the course is more than 91 days past its end date' do
      let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }
      let(:course_wikis) { [wiki1, wiki2] }

      before do
        e = course.end
        stub_wiki(wiki1, 'user1' => [
                    e - 26.days, e - 26.days + 30.minutes, e - 21.days, # 2 sessions during
                    e + 14.days, e + 14.days + 30.minutes,             # 1 session, day 14 after
                    e + 70.days, e + 70.days + 5.minutes,              # 5 edits in the 60-90
                    e + 71.days, e + 72.days, e + 73.days              # survival window
                  ])
        # An es.wikipedia edit that lands mid-cluster in the first during-course session.
        stub_wiki(wiki2, 'user1' => [e - 26.days + 45.minutes])
      end

      it 'fills every per-student metric on the combined cross-wiki timeline' do
        expect(detail_row('user1')).to eq(%w[user1 2 14 1 5])
      end

      it 'defaults a non-returning student to a 30-day gap and zero counts' do
        expect(detail_row('user2')).to eq(%w[user2 0 30 0 0])
      end

      it 'aggregates the per-course summary block' do
        expect(summary_value('participants')).to eq('2')
        expect(summary_value('total editing sessions during course')).to eq('2')
        expect(summary_value('avg days to first independent edit')).to eq('22.0')
        expect(summary_value('avg editing sessions in 30 days after course')).to eq('0.5')
        expect(summary_value('participants with 5+ edits in days 60-90 (survivors)')).to eq('1')
      end

      it 'counts zero-edit and returning participants' do
        # user2 made no edits; user1 edited during the course and returned on day 14.
        expect(summary_value('participants with no editing sessions during course')).to eq('1')
        expect(summary_value('participants who edited in 30 days after course')).to eq('1')
      end
    end

    context 'when the course ended fewer than 31 days ago' do
      let(:course) { create(:course, start: 45.days.ago, end: 15.days.ago) }

      before do
        e = course.end
        stub_wiki(wiki1, 'user1' => [e - 5.days, e - 5.days + 30.minutes]) # 1 during session
      end

      it 'reports during-course sessions but leaves the post-course metrics blank' do
        expect(detail_row('user1')).to eq(['user1', '1', nil, nil, nil])
        expect(summary_value('total editing sessions during course')).to eq('1')
        expect(summary_value('avg days to first independent edit')).to be_nil
        expect(summary_value('avg editing sessions in 30 days after course')).to be_nil
        expect(summary_value('participants with 5+ edits in days 60-90 (survivors)')).to be_nil
      end

      it 'counts zero-edit participants but leaves returning participants blank' do
        # user2 made no edits; the return window has not yet closed, so the
        # returning-participants aggregate cannot be finalized.
        expect(summary_value('participants with no editing sessions during course')).to eq('1')
        expect(summary_value('participants who edited in 30 days after course')).to be_nil
      end
    end

    context 'when the course ended between 31 and 90 days ago' do
      let(:course) { create(:course, start: 95.days.ago, end: 65.days.ago) }

      before do
        e = course.end
        stub_wiki(wiki1, 'user1' => [e - 10.days, e + 5.days]) # 1 during session, returns day 5
      end

      it 'fills the 30-day metrics but leaves the 60-90-day metric blank' do
        expect(detail_row('user1')).to eq(['user1', '1', '5', '1', nil])
        expect(detail_row('user2')).to eq(['user2', '0', '30', '0', nil])
        expect(summary_value('avg days to first independent edit')).to eq('17.5')
        expect(summary_value('avg editing sessions in 30 days after course')).to eq('0.5')
        expect(summary_value('participants with 5+ edits in days 60-90 (survivors)')).to be_nil
      end

      it 'counts zero-edit and returning participants once the window has closed' do
        # user2 made no edits; user1 edited during the course and returned on day 5.
        expect(summary_value('participants with no editing sessions during course')).to eq('1')
        expect(summary_value('participants who edited in 30 days after course')).to eq('1')
      end
    end
  end

  describe 'pagination' do
    let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }

    before do
      e = course.end
      first = response_for([e - 26.days], continue: { 'uccontinue' => 'x' })
      second = response_for([e - 20.days])
      api1 = instance_double(WikiApi)
      allow(WikiApi).to receive(:new).with(wiki1).and_return(api1)
      allow(api1).to receive(:query).and_return(first, second)
    end

    it 'follows the continue token to fetch all pages of contributions' do
      # The two pages are days apart, so both must be fetched to count 2 sessions.
      expect(detail_row('user1')).to eq(['user1', '2', '30', '0', '0'])
    end
  end
end
