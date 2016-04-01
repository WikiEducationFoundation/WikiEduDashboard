import '../testHelper';
import CourseDateUtils from '../../app/assets/javascripts/utils/course_date_utils';

// As of 2016-01-28, this matches the spec data for CourseMeetingsManager
// There are sixteen non-blackout weeks.
const typicalCourse = {
  id: 1,
  start: '2015-08-28',
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
    return expect(result).to.eq(true);
  });

  it('returns false when Weeks and non-empty calendar weeks are equal', () => {
    const sameWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, sameWeeks, exceptions);
    return expect(result).to.eq(false);
  });

  return it('returns false when there are fewer Weeks than non-empty calendar weeks', () => {
    const fewerWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, fewerWeeks, exceptions);
    return expect(result).to.eq(false);
  });
});

describe('CourseDateUtils.openWeeks', () => {
  it('returns the count of weeks with meetings from a weekMeetings array', () => {
    const weekMeetings = ['(M, W, F)', '(M, W)', '()', '(W, T)', '(M, W, F)'];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    return expect(result).to.eq(4);
  });

  it('handles empty arrays', () => {
    const weekMeetings = [];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    return expect(result).to.eq(0);
  });

  return it('handles arrays of all empty weeks', () => {
    const weekMeetings = ['()', '()', '()', '()', '()'];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    return expect(result).to.eq(0);
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
