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
  test(
    'returns true when there are more Weeks than non-empty calendar weeks',
    () => {
      const moreWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
      const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, moreWeeks, exceptions);
      expect(result).toBe(true);
    }
  );

  test('returns false when Weeks and non-empty calendar weeks are equal', () => {
    const sameWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, sameWeeks, exceptions);
    expect(result).toBe(false);
  });

  test(
    'returns false when there are fewer Weeks than non-empty calendar weeks',
    () => {
      const fewerWeeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      const result = CourseDateUtils.moreWeeksThanAvailable(typicalCourse, fewerWeeks, exceptions);
      expect(result).toBe(false);
    }
  );
});

describe('CourseDateUtils.dateProps', () => {
  test('returns an object with date constraints', () => {
    const dateProps = CourseDateUtils.dateProps(typicalCourse);
    expect(typeof dateProps.end.minDate).toBe('object');
    expect(typeof dateProps.timeline_start.maxDate).toBe('object');
    expect(typeof dateProps.timeline_end.minDate).toBe('object');
  });
});

describe('CourseDateUtils.openWeeks', () => {
  test(
    'returns the count of weeks with meetings from a weekMeetings array',
    () => {
      const weekMeetings = [['M', 'W', 'F'], ['M', 'W'], [], ['W', 'T'], ['M', 'W', 'F']];
      const result = CourseDateUtils.openWeeks(weekMeetings);
      expect(result).toBe(4);
    }
  );

  test('handles empty arrays', () => {
    const weekMeetings = [];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    expect(result).toBe(0);
  });

  test('handles arrays of all empty weeks', () => {
    const weekMeetings = [[], [], [], [], []];
    const result = CourseDateUtils.openWeeks(weekMeetings);
    expect(result).toBe(0);
  });
});

describe('courseDateUtils.isDateValid', () => {
  test('returns false for a date of form YYYY-MM', () => {
    const input = '2016-06';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).toBe(false);
  });

  test('returns false for an invalid date of form YYYY-MM-DD', () => {
    const input = '2016-06-31';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).toBe(false);
  });

  test('returns true for a valid date of form YYYY-MM-DD', () => {
    const input = '2016-06-30';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).toBe(true);
  });

  test('returns false for a valid date prior to 2000', () => {
    const input = '1999-06-30';
    const result = CourseDateUtils.isDateValid(input);
    expect(result).toBe(false);
  });
});

describe('CourseDateUtils.formattedDateTime', () => {
  test('returns a date string', () => {
    const input = new Date(2016, 10, 19, 17, 15, 14);
    const output = CourseDateUtils.formattedDateTime(input);
    expect(output).toBe('2016-11-19');
  });
  test('returns a datetime string with timezone if showTime is true', () => {
    const input = new Date(2016, 10, 19, 17, 15, 14);
    const output = CourseDateUtils.formattedDateTime(input, true);
    expect(output).toContain(['2016-11-19 17:15']);
  });
});

describe('courseDateUtils.weeksBeforeTimeline', () => {
  test('rounds times within the same week to zero', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-05' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).toBe(0);
  });
  test('counts whole weeks accurately, Sunday to Sunday', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-09' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).toBe(1);
  });
  test('counts partial weeks if they cross between Sunday-bounded weeks', () => {
    const course = { start: '2017-07-06', timeline_start: '2017-07-10' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).toBe(1);
  });
  test('rounds down to the number of week boundaries crossed', () => {
    const course = { start: '2017-07-02', timeline_start: '2017-07-13' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).toBe(1);
  });
  test('works for longer stretches', () => {
    // Example dates from a Fall 2017 course
    const course = { start: '2017-08-29', timeline_start: '2017-10-23' };
    const output = CourseDateUtils.weeksBeforeTimeline(course);
    expect(output).toBe(8);
  });
});

describe('CourseDateUtils.wouldCreateBlackoutWeek', () => {
  test('returns true if exceptions on all meeting days', () => {
    // 2015-08-01 is a Friday
    // course meets on Tuesdays and Thursdays so we add those as an exception to create a blackout week
    const output = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, '2015-08-28', ['20150825', '20150827']);
    expect(output).toBe(true);
  });

  test('returns false if no exceptions', () => {
    // no exceptions, means that this week is not a blackout one
    const output = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, '2015-08-28', []);
    expect(output).toBe(false);
  });

  test('returns false if an exception is on a non meeting day', () => {
    // set exceptions on both Tuesdays and Thursdays, which are meeting days
    const meeting_exceptions = ['20150825', '20150827'];
    // however, also set an exception for a day that is not a meeting day
    meeting_exceptions.push('20150826');

    const output = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, '2015-08-28', meeting_exceptions);
    // this would cause it to be not a blackout week
    expect(output).toBe(false);
  });

  test('returns false if not all meeting days are exceptions', () => {
    // set exceptions on both Tuesdays which is meeting day
    const meeting_exceptions = ['20150825'];

    // but don't set an exception for a Thursday which is also a meeting day
    const output = CourseDateUtils.wouldCreateBlackoutWeek(typicalCourse, '2015-08-28', meeting_exceptions);
    // this would cause it to be not a blackout week
    expect(output).toBe(false);
  });
});
