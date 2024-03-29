# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_meetings_manager"

describe CourseMeetingsManager do
  # starts with a comma to mimic real data. will fix data later
  let(:day_ex) do
    ",20151013,20151201,20151203,20151208,20151209,
    20151210,20151215,20151217,20151222,
    20151224,20151229,20151231,20160105"
  end
  let(:t_start) { '2015-08-28' } # Friday
  let(:t_end)   { '2016-01-14' } # Thursday
  let(:weekdays) { '0010100' } # Tuesdays and Thursdays
  let(:course_type) { 'ClassroomProgramCourse' }
  let!(:course) do
    create(:course,
           id: 1,
           timeline_start: t_start,
           timeline_end: t_end,
           day_exceptions: day_ex,
           weekdays:,
           type: course_type)
  end

  before do
    # There 21 calendar weeks and 16 non-blackout weeks. This creates weeks
    # that extend beyond the timeline.
    (1..24).each do |week_number|
      create(:week, course_id: 1, order: week_number)
    end
  end

  let(:expected_week_meeting_dates) do
    [[], # August 23 - 29, 2015
     ['2015-09-01'.to_date, '2015-09-03'.to_date],
     ['2015-09-08'.to_date, '2015-09-10'.to_date],
     ['2015-09-15'.to_date, '2015-09-17'.to_date],
     ['2015-09-22'.to_date, '2015-09-24'.to_date],
     ['2015-09-29'.to_date, '2015-10-01'.to_date],
     ['2015-10-06'.to_date, '2015-10-08'.to_date],
     ['2015-10-15'.to_date],
     ['2015-10-20'.to_date, '2015-10-22'.to_date],
     ['2015-10-27'.to_date, '2015-10-29'.to_date],
     ['2015-11-03'.to_date, '2015-11-05'.to_date],
     ['2015-11-10'.to_date, '2015-11-12'.to_date],
     ['2015-11-17'.to_date, '2015-11-19'.to_date],
     ['2015-11-24'.to_date, '2015-11-26'.to_date],
     [], # November 29 - December 5
     ['2015-12-09'.to_date], # December 6 - 12, including exception not on a Tues/Thurs
     [], [], [], # December 13 - January 2
     ['2016-01-07'.to_date], # January 3 - 9
     ['2016-01-12'.to_date, '2016-01-14'.to_date]]
  end

  let(:expected_week_meetings) do
    ['()', # August 23 - 29, 2015
     # August 30 - October 10
     '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)',
     '(Thu)', # October 11 - 17
     # October 18 - November 28
     '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)', '(Tue, Thu)',
     '()', # November 29 - December 5
     '(Wed)', # December 6 - 12, including exception not on a Tues/Thurs
     '()', '()', '()', # December 13 - January 2
     '(Thu)', # January 3 - 9
     '(Tue, Thu)'] # January 10 - 16
  end

  describe '#week_meeting_dates' do
    subject { described_class.new(course).instance_variable_get(:@week_meeting_dates) }

    context 'course with timeline start and end' do
      it 'returns an array of meetings dates for each week, factoring in blackout dates' do
        expect(subject).to eq(expected_week_meeting_dates)
      end
    end
  end

  describe '#week_meetings' do
    subject { described_class.new(course).week_meetings }

    context 'course with timeline start and end' do
      it 'returns an array of day meetings for each week, factoring in blackout dates' do
        expect(subject).to eq(expected_week_meetings)
      end
    end

    context 'course with saturday exception' do
      it 'excludes the specified saturday' do
        saturday_course = create(:course,
                                 id: 10001,
                                 title: 'Saturday',
                                 school: 'University',
                                 term: 'Term',
                                 slug: 'University/Saturday_(Term)',
                                 submitted: false,
                                 passcode: 'passcode',
                                 start: '2019-06-29'.to_date,
                                 end: '2019-11-16'.to_date,
                                 timeline_start: '2019-06-29'.to_date,
                                 timeline_end: '2019-11-16'.to_date,
                                 day_exceptions: '20190706',
                                 weekdays: '0000001',
                                 type: course_type)

        dates = described_class.new(saturday_course).week_meetings
        second_week = dates[1]
        expect(second_week).to eq('()')
      end
    end

    context 'course has no timeline start or end' do
      let(:course_type) { 'LegacyCourse' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'course with no week days, but with day exceptions' do
      let(:weekdays) { '0000000' }

      it 'returns the day exceptions, week by week' do
        # December 6 - 12, with exceptions for three days
        expect(subject).to include('(Tue, Wed, Thu)')
      end
    end
  end

  describe '#day_meetings' do
    subject { described_class.new(course).send(:day_meetings) }

    it 'returns an array of symbols reprensenting the course meeting days' do
      expect(subject).to eq(%i[tuesday thursday])
    end
  end

  describe '#calculate_timeline_week_count' do
    subject { described_class.new(course).instance_variable_get(:@timeline_week_count) }

    context 'course has start and end dates' do
      it 'returns an integer representing the weeks in the timeline, irrespective of blackouts' do
        expect(subject).to eq(21)
      end
    end

    context 'course has no timeline start or end' do
      let(:course_type) { 'LegacyCourse' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#all_potential_meetings' do
    subject { described_class.new(course).send(:all_potential_meetings) }

    let(:expected) do
      [Date.new(2015, 8, 25),
       Date.new(2015, 8, 27),
       Date.new(2015, 9, 1)]
    end

    it 'returns an array of all days the course would have met, irrespective of blackouts' do
      expect(subject.first(3)).to eq(expected)
    end
  end

  describe '#open_weeks' do
    subject { described_class.new(course).open_weeks }
    # an array with 12 elements

    let(:weeks) { %w[foo foo foo foo foo foo foo foo foo foo foo foo] }

    before { allow_any_instance_of(Course).to receive(:weeks).and_return(weeks) }

    context 'course has timeline start/end' do
      it 'returns an int representing the weeks the timeline can accomodate' do
        # There are 16 weeks with meetings, so 4 open weeks.
        expect(subject).to eq(4)
      end
    end

    context 'course has no timeline start or end' do
      let(:course_type) { 'LegacyCourse' }

      it 'returns zero' do
        expect(subject).to be_zero
      end
    end
  end

  describe '#meeting_dates_of' do
    subject { described_class.new(course).meeting_dates_of(week) }

    context 'for a week with meetings' do
      let(:week) { Week.find_by(order: 2) }
      let(:expected_week_dates) { ['2015-09-08'.to_date, '2015-09-10'.to_date] }

      it 'returns the dates of meetings that week' do
        expect(subject).to eq(expected_week_dates)
      end
    end

    context 'for a week outside the timeline range' do
      let(:week) { Week.find_by(order: 20) }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'for a course that only meets on saturdays' do
      let(:week) { Week.find_by(order: 1) }

      it 'returns the class date as saturday' do
        saturday_course = create(:course,
                                 id: 10001,
                                 title: 'Saturday',
                                 school: 'University',
                                 term: 'Term',
                                 slug: 'University/Saturday_(Term)',
                                 submitted: false,
                                 passcode: 'passcode',
                                 start: '2019-06-26'.to_date,
                                 end: '2019-11-18'.to_date,
                                 timeline_start: '2019-06-26'.to_date,
                                 timeline_end: '2019-11-18'.to_date,
                                 weekdays: '0000001',
                                 type: course_type)

        dates = described_class.new(saturday_course).meeting_dates_of(week)
        expect(dates).to eq(['2019-06-29'.to_date])
      end

      it 'allows for saturday to be set as the first day' do
        saturday_course = create(:course,
                                 id: 10001,
                                 title: 'Saturday',
                                 school: 'University',
                                 term: 'Term',
                                 slug: 'University/Saturday_(Term)',
                                 submitted: false,
                                 passcode: 'passcode',
                                 start: '2019-06-29'.to_date,
                                 end: '2019-11-18'.to_date,
                                 timeline_start: '2019-06-29'.to_date,
                                 timeline_end: '2019-11-18'.to_date,
                                 weekdays: '0000001',
                                 type: course_type)

        dates = described_class.new(saturday_course).meeting_dates_of(week)
        expect(dates).to eq(['2019-06-29'.to_date])
      end

      it 'allows for saturday to be set as the last day' do
        saturday_course = create(:course,
                                 id: 10001,
                                 title: 'Saturday',
                                 school: 'University',
                                 term: 'Term',
                                 slug: 'University/Saturday_(Term)',
                                 submitted: false,
                                 passcode: 'passcode',
                                 start: '2019-06-29'.to_date,
                                 end: '2019-11-16'.to_date,
                                 timeline_start: '2019-06-29'.to_date,
                                 timeline_end: '2019-11-16'.to_date,
                                 weekdays: '0000001',
                                 type: course_type)

        last_week = Week.find_by(order: 21)
        dates = described_class.new(saturday_course).meeting_dates_of(last_week)
        expect(dates).to eq(['2019-11-16'.to_date])
      end
    end
  end

  # Should match the javascript function courseDateUtils.weeksBeforeTimeline
  # These tests match those in test/utils/course_date_utils.spec.js
  describe '#weeks_before_timeline' do
    let(:slug) { 'University_of_Chicago/History_of_Skepticism_(Winter_Quarter)' }

    it 'rounds times within the same week to zero' do
      course = create(:course, slug:, start: '2017-07-02', timeline_start: '2017-07-05')
      expect(described_class.new(course).weeks_before_timeline).to be(0)
    end

    it 'counts whole weeks accurately, Sunday to Sunday' do
      course = create(:course, slug:, start: '2017-07-02', timeline_start: '2017-07-09')
      expect(described_class.new(course).weeks_before_timeline).to be(1)
    end

    it 'counts partial weeks if they cross between Sunday-bounded weeks' do
      course = create(:course, slug:, start: '2017-07-06', timeline_start: '2017-07-10')
      expect(described_class.new(course).weeks_before_timeline).to be(1)
    end

    it 'rounds down to the number of week boundaries crossed' do
      course = create(:course, slug:, start: '2017-07-02', timeline_start: '2017-07-13')
      expect(described_class.new(course).weeks_before_timeline).to be(1)
    end

    it 'works for longer stretches' do
      course = create(:course, slug:, start: '2017-08-29', timeline_start: '2017-10-23')
      expect(described_class.new(course).weeks_before_timeline).to be(8)
    end

    it 'works for exactly two weeks between start and timeline start' do
      course = create(:course, slug:, start: '2018-01-09', timeline_start: '2018-01-23')
      expect(described_class.new(course).weeks_before_timeline).to be(2)
    end
  end
end
