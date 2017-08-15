import '../testHelper';
import CourseDateUtils from '../../app/assets/javascripts/utils/course_date_utils';

// As of 2016-01-28, this matches the spec data for CourseMeetingsManager
// There are sixteen non-blackout weeks.
const typicalCourse = {
  id: 1,
  type: 'ClassroomProgramCourse',
  start: '2015-07-28',
  timeline_start: '2015-08-28',
  end: '2016-01-14',
  timeline_end: '2016-01-14',
  weekdays: '0010100',
  day_exceptions: ',20151013,20151201,20151203,20151208,20151209,20151210,20151215,20151217,20151222,20151224,20151229,20151231,20160105'
};

const exceptions = typicalCourse.day_exceptions.split(',');

describe('CourseDateUtils.moreWeeksThanAvailable', () => {
  it('returns true when there are more Weeks than non-empty calendar weeks', () => {
    const moreWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, moreWeeks, exceptions);
    expect(result).to.eq(true);
  });

  it('returns false when Weeks and non-empty calendar weeks are equal', () => {
    const sameWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, sameWeeks, exceptions);
    expect(result).to.eq(false);
  });

  it('returns false when there are fewer Weeks than non-empty calendar weeks', () => {
    const fewerWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, fewerWeeks, exceptions);
    expect(result).to.eq(false);
  });
});

describe('CourseDateUtils.dateProps', () => {
  it('returns an object with date constraints', () => {
    const dateProps = CourseDateUtils.dateProps(typicalCourse);
    expect(typeof dateProps.end.minDate).to.eq('object');
    expect(typeof dateProps.timeline_start.maxDate).to.eq('object');
    expect(typeof dateProps.timeline_end.minDate).to.eq('object');
  });
});

describe('CourseDateUtils.openWeeks', () => {
  it('returns the count of weeks with meetings from a weekMeetings array', () => {
    const weekMeetings = ['(M, W, F)', '(M, W)', '()', '(W, T)', '(M, W, F)'];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    expect(result).to.eq(4);
  });

  it('handles empty arrays', () => {
    const weekMeetings = [];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    expect(result).to.eq(0);
  });

  it('handles arrays of all empty weeks', () => {
    const weekMeetings = ['()', '()', '()', '()', '()'];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    expect(result).to.eq(0);
  });
});

describe('courseDateUtils.isDateValid', () => {
  it('returns false for a date of form YYYY-MM', () => {
    const input = '2016-06';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).to.eq(false);
  });

  it('returns false for an invalid date of form YYYY-MM-DD', () => {
    const input = '2016-06-31';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).to.eq(false);
  });

  it('returns true for a valid date of form YYYY-MM-DD', () => {
    const input = '2016-06-30';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).to.eq(true);
  });

  it('returns false for a valid date prior to 2000', () => {
    const input = '1999-06-30';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).to.eq(false);
  });
});

describe('CourseDateUtils.validationRegex', () => {
  it('returns a regex that matches YYYY-[M]M-[D]D', () => {
    const validationRegex = CourseDateUtils.validationRegex();
    expect('2015-02-24'.match(validationRegex)[0]).to.eq('2015-02-24');
    expect('2015-13-25'.match(validationRegex)).to.be.null;
  });
});

describe('CourseDateUtils.formattedDateTime', () => {
  it('returns a date string', () => {
    const input = new Date(2016, 10, 19, 17, 15, 14);
    const output = CourseDateUtils.formattedDateTime(input);
    expect(output).to.eq('2016-11-19');
  });
  it('returns a datetime string with timezone if showTime is true', () => {
    const input = new Date(2016, 10, 19, 17, 15, 14);
    const output = CourseDateUtils.formattedDateTime(input, true);
    expect(output).to.contain('2016-11-19 17:15');
  });
});

describe('courseDateUtils.weeksBeforeTimeline', () => {
  it('rounds times within the same week to zero', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-05' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).to.be.eq(0);
  });
  it('counts whole weeks accurately, Sunday to Sunday', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-09' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).to.be.eq(1);
  });
  it('counts partial weeks if they cross between Sunday-bounded weeks', () => {
    const course = { start: '2017-07-06', timeline_start: '2017-07-10' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).to.be.eq(1);
  });
  it('rounds down to the number of week boundaries crossed', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-13' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).to.be.eq(1);
  });
  it('works for longer stretches', () => {
    // Example dates from a Fall 2017 course
    const course = { start: '2017-08-29', timeline_start: '2017-10-23' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).to.be.eq(8);
  });
});

// describe 'CourseDateUtils.wouldCreateBlackoutWeek', ->
//   one_of_two_meetings = '2015-11-24'
//   result = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, one_of_two_meetings, exceptions)
//   expect(result).to.eq false
//
//   only_meeting = '2015-12-09'
//   result = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, only_meeting, exceptions)
//   expect(result).to.eq true
//
// describe 'CourseDateUtils.weekMeetings', ->
// describe 'CourseDateUtils.meetings', ->
// describe 'CourseDateUtils.courseMeets', ->
