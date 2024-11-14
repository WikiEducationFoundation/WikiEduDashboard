import { filter } from 'lodash-es';
import {
  isValid,
  format,
  parseISO,
  isAfter,
  differenceInMonths,
  startOfWeek,
  addDays,
  differenceInWeeks,
  endOfWeek,
  getDay,
  addWeeks,
  isBefore,
} from 'date-fns';
import { toDate } from './date_utils';

const CourseDateUtils = {
  isDateValid(date) {
    return /^20\d{2}-\d{2}-\d{2}/.test(date) && isValid(toDate(date));
  },

  /**
   * @param  {Date} datetime
   * @param  {boolean} showTime=false
   */
  formattedDateTime(datetime, showTime = false) {
    let timeZoneAbbr = '';
    let timeFormat = '';

    if (showTime) {
      timeFormat = ' HH:mm';
      try {
        timeZoneAbbr = ' ';
        timeZoneAbbr += datetime.toString().split('(')[1].slice(0, -1);
      } catch (err) {
        timeZoneAbbr = '';
      }
    }
    const dateFormat = `yyyy-MM-dd${timeFormat}`;
    return format(datetime, dateFormat) + timeZoneAbbr;
  },

  // Returns an object of minDate and maxDate props for each date field of a course
  dateProps(course) {
    const startDate = parseISO(course.start);
    const props = {
      end: {
        minDate: startDate
      },
      timeline_start: {
        minDate: startDate,
        maxDate: parseISO(course.timeline_end)
      },
      timeline_end: {
        minDate: parseISO(course.timeline_start),
        maxDate: parseISO(course.end)
      }
    };
    return props;
  },

  // This method takes a current version of a course and an updated key-value pair
  // for changing one of the date fields and returns a course where all the dates
  // are consistent with each other.
  updateCourseDates(prevCourse, valueKey, value) {
    const updatedCourse = Object.assign({}, prevCourse); // clone the course
    updatedCourse[valueKey] = value;
    // Just return with the new value if it doesn't pass validation
    // or if it it lacks timeline dates
    if (!this.isDateValid(value) || !updatedCourse.timeline_start) { return updatedCourse; }
    if (isAfter(toDate(updatedCourse.start), toDate(updatedCourse.timeline_start)) && valueKey !== 'timeline_start') {
      updatedCourse.timeline_start = updatedCourse.start;
    }
    if (isAfter(toDate(updatedCourse.timeline_start), toDate(updatedCourse.timeline_end)) && valueKey !== 'timeline_end') {
      updatedCourse.timeline_end = updatedCourse.timeline_start;
    }
    if (updatedCourse.timeline_end && isAfter(toDate(updatedCourse.timeline_end), toDate(updatedCourse.end)) && valueKey !== 'end') {
      updatedCourse.end = updatedCourse.timeline_end;
    }
    if (isAfter(toDate(updatedCourse.timeline_start), toDate(updatedCourse.end)) && valueKey !== 'timeline_start') {
      updatedCourse.timeline_start = updatedCourse.end;
    }

    // If the dates were changed by extending the course end, and the assignment end
    // was previously the same as the course end, then extend the timeline end to match.
    if (prevCourse.end === prevCourse.timeline_end && valueKey !== 'timeline_end') {
      updatedCourse.timeline_end = updatedCourse.end;
    }

    return updatedCourse;
  },

  // Maximum tracking length of a year, plus a little bit of wiggle room.
  // We want to make sure long-running events get broken up into smaller
  // segments, because huge long-running courses cause performance problems
  // with the Dashboard data update process.
  MAX_MONTHS: 13,

  courseTooLong(course) {
    return differenceInMonths(toDate(course.end), toDate(course.start)) > this.MAX_MONTHS;
  },

  moreWeeksThanAvailable(course, weeks, exceptions) {
    if (!weeks || !weeks.length) { return false; }
    const nonBlackoutWeeks = filter(
      this.weekMeetings(course, exceptions),
      mtg => mtg.length > 0
    );
    return weeks.length > nonBlackoutWeeks.length;
  },

  wouldCreateBlackoutWeek(course, day, exceptions) {
    const selectedDay = toDate(day);
    let noMeetingsThisWeek = true;
    [0, 1, 2, 3, 4, 5, 6].forEach((i) => {
      const wkDay = format(addDays(startOfWeek(selectedDay), i), 'yyyyMMdd');
      if (this.courseMeets(course.weekdays, i, wkDay, exceptions.join(','))) {
        return (noMeetingsThisWeek = false);
      }
    });
    return noMeetingsThisWeek;
  },

  weeksBeforeTimeline(course) {
    const courseStart = startOfWeek(toDate(course.start));
    const timelineStart = startOfWeek(toDate(course.timeline_start));
    return differenceInWeeks(timelineStart, courseStart);
  },

  // Returns array describing weekday meetings for each week
  // Ex: [["Sunday (01/09)"], ["Sunday (01/16)", "Wednesday (01/19)", "Thursday (01/20)"], []]
  weekMeetings(course, exceptions) {
    const weekEnd = endOfWeek(toDate(course.timeline_end));
    let weekStart = startOfWeek(toDate(course.timeline_start));
    const firstWeekStart = getDay(toDate(course.timeline_start));
    const courseWeeks = differenceInWeeks(weekEnd, weekStart, { roundingMethod: 'round' });
    const meetings = [];

    // eslint-disable-next-line no-restricted-syntax
    for (const week of range(0, (courseWeeks - 1), true)) {
      weekStart = addWeeks(startOfWeek(toDate(course.timeline_start)), week);

      // Account for the first partial week, which may not have 7 days.
      let firstDayOfWeek;
      if (week === 0) {
        firstDayOfWeek = firstWeekStart;
      } else {
        firstDayOfWeek = 0;
      }

      const ms = [];
      // eslint-disable-next-line no-restricted-syntax
      for (const i of range(firstDayOfWeek, 6, true)) {
        const day = addDays(weekStart, i);
        if (course && this.courseMeets(course.weekdays, i, format(day, 'yyyyMMdd'), exceptions)) {
          ms.push(format(day, 'EEEE (MM/dd)'));
        }
      }
      meetings.push(ms);
    }
    return meetings;
  },
  courseMeets(weekdays, i, formatted, exceptions) {
    if (!exceptions && exceptions !== '') {
      return false;
    }
    exceptions = exceptions.split ? exceptions.split(',') : exceptions;

    if (weekdays[i] === '1' && !exceptions.includes(formatted)) {
      return true;
    }
    if (weekdays[i] === '0' && exceptions.includes(formatted)) {
      return true;
    }
    return false;
  },

  // Takes a week weekMeetings array and returns the count of non-empty weeks
  openWeeks(weekMeetings) {
    let openWeekCount = 0;
    weekMeetings.forEach((meetingArray) => {
      if (meetingArray.length > 0) {
        return openWeekCount += 1;
      }
    });
    return openWeekCount;
  },

  isEnded(course) {
    return isBefore(toDate(course.end), new Date());
  },

  currentWeekIndex(timelineStart) {
    const diff = differenceInWeeks(startOfWeek(new Date()), startOfWeek(toDate(timelineStart)));
    return Math.max(diff, 0);
  },

  currentWeekOrder(timelineStart) {
    // Week order is indexed from 1, so we add 1 to the number of weeks that have
    // passed since the start of the timeline to get the current week.
    return this.currentWeekIndex(timelineStart) + 1;
  },

  extractDate(date) {
    // Use a regular expression to match the date format (MM/DD).
    // The regex breakdown:
    // - `\(`: Matches the literal opening parenthesis '('.
    // - `\s*`: Matches any whitespace characters (spaces or tabs) zero or more times.
    // - `(\d{1,2}\/\d{1,2})`: Capturing group that matches:
    //   - `\d{1,2}`: Exactly one or two digits (for MM).
    //   - `\/`: Matches the literal '/' character.
    //   - `\d{1,2}`: Exactly one or two digits (for DD).
    // - `\s*`: Matches any whitespace characters zero or more times.
    // - `\)`: Matches the literal closing parenthesis ')'.

    const match = date.trim().match(/\(\s*(\d{1,2}\/\d{1,2})\s*\)/);

    // Check if a match was found and return the first capturing group (MM/DD).
    // If no match is found, return null.
    return match && match[1] ? match[1] : null;
  }

};

function* range(left, right, inclusive) {
  const ascending = left < right;

  let endOfRange;
  if (!inclusive) {
    endOfRange = right;
  } else if (ascending) {
    endOfRange = right + 1;
  } else {
    endOfRange = right - 1;
  }

  for (let i = left; ascending ? i < endOfRange : i > endOfRange; ascending ? i += 1 : i -= 1) {
    yield i;
  }
}

export default CourseDateUtils;
