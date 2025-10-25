import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import { compact } from 'lodash-es';
import WeekdayPicker from './weekday_picker.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { toDate } from '../../utils/date_utils.js';
import { format, getDay } from 'date-fns';

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

const Calendar = ({
  course,
  weeks,
  calendarInstructions,
  editable,
  shouldShowSteps,
  updateCourse
}) => {
  const [initialMonth, setInitialMonth] = useState(toDate(course.start));

  useEffect(() => {
    setInitialMonth(toDate(course.start));
  }, [course.start]);

  const inrange = useCallback(
    (day) => {
      if (course.start === undefined) { return false; }
      const start = new Date(course.start);
      const end = new Date(course.end);
      return start <= day && day <= end;
    },
    [course.start, course.end]
  );

  const selectDay = useCallback(
    (day) => {
      let exceptions;
      if (!inrange(day)) { return; }
      if (course.day_exceptions === undefined) {
        course.day_exceptions = '';
        exceptions = [];
      } else {
        exceptions = course.day_exceptions.split(',');
      }
      const formatted = format(day, 'yyyyMMdd');
      if (__in__(formatted, exceptions)) {
        exceptions.splice(exceptions.indexOf(formatted), 1);
      } else {
        exceptions.push(formatted);
        const utils = CourseDateUtils;
        if (utils.wouldCreateBlackoutWeek(course, day, exceptions) && utils.moreWeeksThanAvailable(course, weeks, exceptions)) {
          alert(I18n.t('timeline.blackout_week_created'));
          return;
        }
      }
      const toPass = course;
      toPass.day_exceptions = exceptions.join(',');
      toPass.no_day_exceptions = compact(exceptions).length === 0;
      return updateCourse(toPass);
    },
    [course, updateCourse, inrange, CourseDateUtils]
  );

  const selectWeekday = useCallback(
    (e, weekday) => {
      const weekdays = course.weekdays ? course.weekdays.split('') : [];
      weekdays[weekday] = weekdays[weekday] === '1' ? '0' : '1';
      const toPass = course;
      toPass.weekdays = weekdays.join('');
      return updateCourse(toPass);
    },
    [course, updateCourse]
  );

  const modifiers = {
    ['outrange']: (day) => {
      return !inrange(day);
    },
    ['selected']: (day) => {
      if ((course.weekdays !== undefined) && course.weekdays.charAt(day) === '1') {
        return true;
      } else if (day < 8) {
        return false;
      }

      const formatted = format(day, 'yyyyMMdd');
      const inrangeDay = inrange(day);
      let exception = false;
      let weekday = false;
      if (course.day_exceptions !== undefined) {
        exception = __in__(formatted, course.day_exceptions.split(','));
      }
      if (course.weekdays) {
        // from 0 to 6. 0 is sunday
        const weekNumber = getDay(day);
        weekday = course.weekdays.charAt(weekNumber) === '1';
      }
      return inrangeDay && ((weekday && !exception) || (!weekday && exception));
    },
    ['highlighted']: (day) => {
      if (day <= 7) { return false; }
      return inrange(day);
    },
    ['bordered']: (day) => {
      if (day <= 7) { return false; }
      if (!course.day_exceptions || !course.weekdays) { return false; }
      const formatted = format(day, 'yyyyMMdd');
      const inrangeDay = inrange(day);
      const exception = __in__(formatted, course.day_exceptions.split(','));
      const weekNumber = getDay(day);
      const weekday = course.weekdays.charAt(weekNumber) === '1';
      return inrangeDay && exception && weekday;
    }
  };

  const editDaysText = I18n.t('courses.calendar.select_meeting_days');
  const editCalendarText = calendarInstructions;

  let editingDays;
  let editingCalendar;
  if (editable) {
    if (shouldShowSteps) {
      editingDays = (<h2>2.<small>{editDaysText}</small></h2>);
      editingCalendar = (
        <h2>3.<small className="no-baseline">{editCalendarText}</small></h2>
      );
    } else {
      editingDays = (<p>{editDaysText}</p>);
      editingCalendar = (
        <p>{editCalendarText}</p>
      );
    }
  }

  const onWeekdayClick = editable ? selectWeekday : null;
  const onDayClick = editable ? selectDay : null;

  return (
    <div>
      <div className="course-dates__step">
        {editingDays}
        <WeekdayPicker
          modifiers={modifiers}
          onWeekdayClick={onWeekdayClick}
        />
      </div>
      <hr />
      <div className="course-dates__step">
        <div className="course-dates__calendar-container">
          {editingCalendar}
          <DayPicker
            modifiers={modifiers}
            onDayClick={onDayClick}
            initialMonth={initialMonth}
          />
          <div className="course-dates__calendar-key">
            <h3>{I18n.t('courses.calendar.legend')}</h3>
            <ul>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--selected">6</div>
                <span>{I18n.t('courses.calendar.legend_class_meeting')}</span>
              </li>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted">6</div>
                <span>{I18n.t('courses.calendar.legend_class_not_meeting')}</span>
              </li>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--bordered">6</div>
                <span>{I18n.t('courses.calendar.legend_class_canceled')}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};


Calendar.propTypes = {
  course: PropTypes.object.isRequired,
  weeks: PropTypes.array,
  calendarInstructions: PropTypes.string,
  editable: PropTypes.bool,
  shouldShowSteps: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired
};

export default Calendar;
