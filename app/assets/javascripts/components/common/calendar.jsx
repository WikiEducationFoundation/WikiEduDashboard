import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import DayPicker from "react-day-picker";
import { compact } from "lodash-es";
import WeekdayPicker from "./weekday_picker.jsx";
import CourseDateUtils from "../../utils/course_date_utils.js";
import { toDate } from "../../utils/date_utils.js";
import { format, getDay, isValid } from "date-fns";
const _in_ = (needle, haystack) => haystack.indexOf(needle) >= 0;
const Calendar = ({
  course,
  weeks,
  calendarInstructions,
  editable,
  shouldShowSteps,
  updateCourse,
}) => {
  const [initialMonth, setInitialMonth] = useState(toDate(course.start));
  const [exceptions, setExceptions] = useState(
    course.day_exceptions ? course.day_exceptions.split(",") : []
  );
  const [weekdays, setWeekdays] = useState(
    course.weekdays ? course.weekdays.split("") : []
  );
  useEffect(() => {
    if (course.start) {
      setInitialMonth(toDate(course.start));
    }
  }, [course.start]);
  const selectDay = (day) => {
    if (!inrange(day)) return;
    const formatted = format(day, "yyyyMMdd");
    if (_in_(formatted, exceptions)) {
      setExceptions(exceptions.filter((exception) => exception !== formatted));
    } else {
      setExceptions([...exceptions, formatted]);
      if (
        CourseDateUtils.wouldCreateBlackoutWeek(course, day, exceptions) &&
        CourseDateUtils.moreWeeksThanAvailable(course, weeks, exceptions)
      ) {
        alert(I18n.t("timeline.blackout_week_created"));
        return false;
      }
    }
    course.day_exceptions = exceptions.join(",");
    course.no_day_exceptions = compact(exceptions).length === 0;
    updateCourse(course);
  };
  const selectWeekday = (e, weekday) => {
    weekdays[weekday] = weekdays[weekday] === "1" ? "0" : "1";
    course.weekdays = weekdays.join("");
    updateCourse(course);
  };
  const inrange = (day) => {
    const start = new Date(course.start);
    const end = new Date(course.end);
    return start < day && day < end;
  };
  const modifiers = {
    outrange: (day) => !inrange(day),
    selected: (day) => {
      if (weekdays[getDay(day)] === "1") return true;
      const formatted = format(day, "yyyyMMdd");
      return (
        inrange(day) &&
        (_in_(formatted, exceptions) || !_in_(formatted, exceptions))
      );
    },
    highlighted: (day) => inrange(day),
    bordered: (day) => {
      if (day <= 7) return false;
      const formatted = format(day, "yyyyMMdd");
      return (
        inrange(day) &&
        _in_(formatted, exceptions) &&
        weekdays[getDay(day)] === "1"
      );
    },
  };
  const editDaysText = I18n.t("courses.calendar.select_meeting_days");
  const editCalendarText = calendarInstructions;
  let editingDays;
  let editingCalendar;
  if (editable) {
    if (shouldShowSteps) {
      editingDays = (
        <h2>
          2.<small>{editDaysText}</small>
        </h2>
      );
      editingCalendar = (
        <h2>
          3.<small className="no-baseline">{editCalendarText}</small>
        </h2>
      );
    } else {
      editingDays = <p>{editDaysText}</p>;
      editingCalendar = <p>{editCalendarText}</p>;
    }
  }
  return (
    <div>
      <div className="course-dates__step">
        {editingDays}
        <WeekdayPicker modifiers={modifiers} onWeekdayClick={selectWeekday} />
      </div>
      <hr />
      <div className="course-dates__step">
        <div className="course-dates__calendar-container">
          {editingCalendar}
          <DayPicker
            modifiers={modifiers}
            onDayClick={selectDay}
            initialMonth={initialMonth}
          />
          <div className="course-dates__calendar-key">
            <h3>{I18n.t("courses.calendar.legend")}</h3>
            <ul>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--selected">
                  6
                </div>
                <span>{I18n.t("courses.calendar.legend_class_meeting")}</span>
              </li>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted">
                  6
                </div>
                <span>
                  {I18n.t("courses.calendar.legend_class_not_meeting")}
                </span>
              </li>
              <li>
                <div className="DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--bordered">
                  6
                </div>
                <span>{I18n.t("courses.calendar.legend_class_canceled")}</span>
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
  updateCourse: PropTypes.func.isRequired,
};
export default Calendar;

