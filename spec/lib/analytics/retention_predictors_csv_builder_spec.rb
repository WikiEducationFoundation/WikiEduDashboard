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

  # One page of a user's pre-course contributions, out of `total` of them.
  # Pages at the real API's 500-per-page limit, so the builder's
  # stop-counting-at-the-threshold pagination gets exercised for real.
  def prior_edits_response(total, params)
    offset = (params['uccontinue'] || params[:uccontinue]).to_i
    remaining = total - offset
    page = [remaining, 500].min
    continue = remaining > page ? { 'uccontinue' => (offset + page).to_s } : nil
    response_for([Time.zone.now] * page, continue:)
  end

  # Stubs WikiApi.new(wiki) for both queries the builder makes. The during-course
  # timeline query is bounded by :ucend; the pre-course edit count query is not,
  # which is how the stub tells them apart. `contribs_by_user` maps
  # username => [Time, ...]; `prior_edits` maps username => edit count.
  def stub_wiki(wiki, contribs_by_user, prior_edits = {})
    api = instance_double(WikiApi)
    allow(WikiApi).to receive(:new).with(wiki).and_return(api)
    allow(api).to receive(:query) do |params|
      if params.key?(:ucend)
        response_for(contribs_by_user.fetch(params[:ucuser], []))
      else
        prior_edits_response(prior_edits.fetch(params[:ucuser], 0), params)
      end
    end
  end

  let(:table) { CSV.parse(described_class.new(course).generate_csv) }

  # full "label,first course,returning participants" summary row
  def summary_row(label)
    table.find { |row| row[0] == label }
  end

  # first-course column of a summary row
  def summary_value(label)
    summary_row(label)&.at(1)
  end

  # returning-participant column of a summary row
  def returning_value(label)
    summary_row(label)&.at(2)
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
        expect(detail_row('user1')).to eq(['user1', '2', '14', '1', '5', '0', nil, '0', nil])
      end

      it 'defaults a non-returning student to a 30-day gap and zero counts' do
        expect(detail_row('user2')).to eq(['user2', '0', '30', '0', '0', '0', nil, '0', nil])
      end

      it 'aggregates the per-course summary block' do
        expect(summary_value('participants')).to eq('2')
        expect(summary_value('total editing sessions during course')).to eq('2')
        expect(summary_value('avg days to first independent edit')).to eq('22.0')
        expect(summary_value('avg editing sessions in 30 days after course')).to eq('0.5')
        expect(summary_value('participants with 1+ edits in days 60-90')).to eq('1')
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
        expect(detail_row('user1')).to eq(['user1', '1', nil, nil, nil, '0', nil, '0', nil])
        expect(summary_value('total editing sessions during course')).to eq('1')
        expect(summary_value('avg days to first independent edit')).to be_nil
        expect(summary_value('avg editing sessions in 30 days after course')).to be_nil
        expect(summary_value('participants with 1+ edits in days 60-90')).to be_nil
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
        expect(detail_row('user1')).to eq(['user1', '1', '5', '1', nil, '0', nil, '0', nil])
        expect(detail_row('user2')).to eq(['user2', '0', '30', '0', nil, '0', nil, '0', nil])
        expect(summary_value('avg days to first independent edit')).to eq('17.5')
        expect(summary_value('avg editing sessions in 30 days after course')).to eq('0.5')
        expect(summary_value('participants with 1+ edits in days 60-90')).to be_nil
        expect(summary_value('participants with 5+ edits in days 60-90 (survivors)')).to be_nil
      end

      it 'counts zero-edit and returning participants once the window has closed' do
        # user2 made no edits; user1 edited during the course and returned on day 5.
        expect(summary_value('participants with no editing sessions during course')).to eq('1')
        expect(summary_value('participants who edited in 30 days after course')).to eq('1')
      end
    end

    context 'when participants differ across the 1+ and 5+ edit thresholds' do
      let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }

      before do
        e = course.end
        stub_wiki(wiki1,
                  # user1: 2 edits in the window (1+ but below the 5+ survivor threshold).
                  'user1' => [e + 65.days, e + 80.days],
                  # user2: 6 edits in the window (counts toward both thresholds).
                  'user2' => [e + 61.days, e + 62.days, e + 63.days,
                              e + 64.days, e + 65.days, e + 66.days])
      end

      it 'counts each threshold independently' do
        expect(summary_value('participants with 1+ edits in days 60-90')).to eq('2')
        expect(summary_value('participants with 5+ edits in days 60-90 (survivors)')).to eq('1')
      end
    end
  end

  describe 'long-term Wikipedians' do
    let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }

    context 'when a participant edited 1000+ times before the course' do
      before do
        e = course.end
        timeline = [e - 10.days, e + 5.days, e + 70.days]
        stub_wiki(wiki1, { 'user1' => timeline, 'user2' => timeline },
                  { 'user1' => 1000 })
      end

      it 'reports them in the detail block, flagged and capped at the threshold' do
        expect(detail_row('user1'))
          .to eq(['user1', '1', '5', '1', '1', '1000+', 'yes', '0', nil])
      end

      it 'leaves them out of every summary aggregate' do
        # Both students have identical timelines, so any aggregate that still
        # counted user1 would be doubled.
        expect(summary_value('participants')).to eq('1')
        expect(summary_value('long-term Wikipedians (excluded from all counts)')).to eq('1')
        expect(summary_value('total editing sessions during course')).to eq('1')
        expect(summary_value('participants who edited in 30 days after course')).to eq('1')
        expect(summary_value('participants with 1+ edits in days 60-90')).to eq('1')
      end
    end

    context 'when a participant edited just under 1000 times before the course' do
      before do
        stub_wiki(wiki1, { 'user1' => [] }, { 'user1' => 999 })
      end

      it 'reports the exact count and counts them as an ordinary participant' do
        # 999 spans two pages of contributions, so the count is only right if
        # pagination continued past the first page.
        expect(detail_row('user1')&.at(5)).to eq('999')
        expect(detail_row('user1')&.at(6)).to be_nil
        expect(summary_value('participants')).to eq('2')
        expect(summary_value('long-term Wikipedians (excluded from all counts)')).to eq('0')
      end
    end

    context 'when prior edits are spread across more than one course wiki' do
      let(:course_wikis) { [wiki1, wiki2] }

      before do
        stub_wiki(wiki1, { 'user1' => [] }, { 'user1' => 600 })
        stub_wiki(wiki2, { 'user1' => [] }, { 'user1' => 500 })
      end

      it 'sums them across wikis to reach the threshold' do
        expect(detail_row('user1')&.at(5)).to eq('1000+')
        expect(detail_row('user1')&.at(6)).to eq('yes')
      end
    end

    context 'when every participant is a long-term Wikipedian' do
      before do
        stub_wiki(wiki1, { 'user1' => [], 'user2' => [] },
                  { 'user1' => 1000, 'user2' => 1000 })
      end

      it 'leaves the aggregates blank rather than reporting a column of zeros' do
        expect(summary_value('participants')).to eq('0')
        expect(summary_value('long-term Wikipedians (excluded from all counts)')).to eq('2')
        expect(summary_value('total editing sessions during course')).to be_nil
        expect(summary_value('participants with 1+ edits in days 60-90')).to be_nil
      end
    end
  end

  describe 'returning participants' do
    let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }
    let(:earlier_course) do
      create(:course, slug: 'School/Earlier_course_(2014)',
                      start: 2.years.ago, end: 20.months.ago)
    end
    let(:later_course) do
      create(:course, slug: 'School/Later_course_(2016)',
                      start: 10.days.ago, end: 5.days.ago)
    end

    before do
      create(:courses_user, course: earlier_course, user: user2,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      # user1 is also in a course that started later, which is not a prior course.
      create(:courses_user, course: later_course, user: user1,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      e = course.end
      stub_wiki(wiki1, 'user1' => [e - 10.days], 'user2' => [e - 10.days, e - 9.days])
    end

    it 'names the prior course in the detail block' do
      expect(detail_row('user2')).to eq(['user2', '2', '30', '0', '0', '0', nil, '1',
                                         'School/Earlier_course_(2014)'])
    end

    it 'treats a course that started later as no prior course at all' do
      expect(detail_row('user1')).to eq(['user1', '1', '30', '0', '0', '0', nil, '0', nil])
    end

    it 'aggregates them in a column of their own' do
      expect(summary_row('Summary')).to eq(['Summary', 'first course', 'returning participants'])
      expect(summary_value('participants')).to eq('1')
      expect(returning_value('participants')).to eq('1')
      expect(summary_value('total editing sessions during course')).to eq('1')
      expect(returning_value('total editing sessions during course')).to eq('2')
    end
  end

  describe 'pagination' do
    let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }

    before do
      e = course.end
      pages = [response_for([e - 26.days], continue: { 'uccontinue' => 'x' }),
               response_for([e - 20.days])]
      api1 = instance_double(WikiApi)
      allow(WikiApi).to receive(:new).with(wiki1).and_return(api1)
      allow(api1).to receive(:query) do |params|
        if !params.key?(:ucend) || params[:ucuser] != 'user1'
          response_for([])
        else
          params['uccontinue'] ? pages[1] : pages[0]
        end
      end
    end

    it 'follows the continue token to fetch all pages of contributions' do
      # The two pages are days apart, so both must be fetched to count 2 sessions.
      expect(detail_row('user1')).to eq(['user1', '2', '30', '0', '0', '0', nil, '0', nil])
    end
  end
end
