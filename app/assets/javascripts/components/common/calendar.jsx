import React, { useState, useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import { compact } from 'lodash-es';
import WeekdayPicker from './weekday_picker.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { toDate } from '../../utils/date_utils.js';
import { format, getDay, isValid } from 'date-fns';

const Calendar = ({
  course,
  weeks,
  calendarInstructions,
  editable,
  shouldShowSteps,
  updateCourse
}) => {
  const [initialMonth, setInitialMonth] = useState(() => toDate(course.start));

  useEffect(() => {
    setInitialMonth(toDate(course.start));
  }, [course.start]);

  const isValidDateRange = useMemo(() => {
    const start = toDate(course.start);
    const end = toDate(course.end);
    return isValid(start) && isValid(end);
  }, [course.start, course.end]);

  if (!isValidDateRange) {
    return null;
  }

  const inrange = (day) => {
    if (course.start === undefined) return false;
    const start = new Date(course.start);
    const end = new Date(course.end);
    return start < day && day < end;
  };

  const selectDay = (day) => {
    if (!inrange(day)) return;

    let exceptions = course.day_exceptions ? course.day_exceptions.split(',') : [];
    const formatted = format(day, 'yyyyMMdd');

    if (exceptions.includes(formatted)) {
      exceptions = exceptions.filter(d => d !== formatted);
    } else {
      exceptions.push(formatted);
      const utils = CourseDateUtils;
      if (utils.wouldCreateBlackoutWeek(course, day, exceptions)
        && utils.moreWeeksThanAvailable(course, weeks, exceptions)) {
        alert(I18n.t('timeline.blackout_week_created'));
        return false;
      }
    }

    const updatedCourse = {
      ...course,
      day_exceptions: exceptions.join(','),
      no_day_exceptions: compact(exceptions).length === 0
    };

    updateCourse(updatedCourse);
  };

  const selectWeekday = (e, weekday) => {
    const weekdays = course.weekdays ? course.weekdays.split('') : Array(7).fill('0');
    weekdays[weekday] = weekdays[weekday] === '1' ? '0' : '1';

    const updatedCourse = {
      ...course,
      weekdays: weekdays.join('')
    };

    updateCourse(updatedCourse);
  };

  const modifiers = {
    outrange: day => !inrange(day),
    selected: (day) => {
      if (day < 8) return false;
      const formatted = format(day, 'yyyyMMdd');
      const exception = course.day_exceptions?.split(',').includes(formatted);
      const weekNumber = getDay(day);
      const weekday = course.weekdays?.[weekNumber] === '1';
      return inrange(day) && ((weekday && !exception) || (!weekday && exception));
    },
    highlighted: day => day > 7 && inrange(day),
    bordered: (day) => {
      if (day <= 7 || !course.day_exceptions || !course.weekdays) return false;
      const formatted = format(day, 'yyyyMMdd');
      const exception = course.day_exceptions.split(',').includes(formatted);
      const weekNumber = getDay(day);
      const weekday = course.weekdays[weekNumber] === '1';
      return inrange(day) && exception && weekday;
    }
  };

  const weekdayModifiers = {
    selected: weekday => course.weekdays && course.weekdays[weekday] === '1'
  };

  const editDaysText = I18n.t('courses.calendar.select_meeting_days');
  const editCalendarText = calendarInstructions;

  let editingDays = null;
  let editingCalendar = null;

  if (editable) {
    if (shouldShowSteps) {
      editingDays = <h2>2.<small>{editDaysText}</small></h2>;
      editingCalendar = <h2>3.<small className="no-baseline">{editCalendarText}</small></h2>;
    } else {
      editingDays = <p>{editDaysText}</p>;
      editingCalendar = <p>{editCalendarText}</p>;
    }
  }

  const onWeekdayClick = editable ? selectWeekday : null;
  const onDayClick = editable ? selectDay : null;

  return (
    <div>
      <div className="course-dates__step">
        {editingDays}
        <WeekdayPicker
          modifiers={weekdayModifiers}
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
  course: PropTypes.object,
  weeks: PropTypes.array,
  calendarInstructions: PropTypes.string,
  editable: PropTypes.bool,
  shouldShowSteps: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired
};

export default Calendar;
