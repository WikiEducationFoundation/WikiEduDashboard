import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import _ from 'lodash';

import WeekdayPicker from './weekday_picker.jsx';
import CourseActions from '../../actions/course_actions.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

const Calendar = createReactClass({
  displayName: 'Calendar',
  propTypes: {
    course: PropTypes.object,
    weeks: PropTypes.array,
    calendarInstructions: PropTypes.string,
    editable: PropTypes.bool,
    shouldShowSteps: PropTypes.bool
  },

  getInitialState() {
    return ({ initialMonth: moment(this.props.course.start, 'YYYY-MM-DD').toDate() });
  },
  componentWillReceiveProps(nextProps) {
    if (nextProps.course.start !== moment(this.state.initialMonth).format('YYYY-MM-DD')) {
      return this.setState(
        { initialMonth: moment(nextProps.course.start, 'YYYY-MM-DD').toDate() });
    }
  },
  shouldComponentUpdate(nextProps) {
    if (nextProps.course) {
      const start = moment(nextProps.course.start, 'YYYY-MM-DD');
      const end = moment(nextProps.course.end, 'YYYY-MM-DD');
      return start.isValid() && end.isValid();
    }
    return true;
  },
  selectDay(e, day) {
    let exceptions;
    if (!this.inrange(day)) { return; }
    const { course } = this.props;
    if (course.day_exceptions === undefined) {
      course.day_exceptions = '';
      exceptions = [];
    } else {
      exceptions = course.day_exceptions.split(',');
    }
    const formatted = moment(day).format('YYYYMMDD');
    if (__in__(formatted, exceptions)) {
      exceptions.splice(exceptions.indexOf(formatted), 1);
    } else {
      exceptions.push(formatted);
      const utils = CourseDateUtils;
      if (utils.wouldCreateBlackoutWeek(this.props.course, day, exceptions) && utils.moreWeeksThanAvailable(this.props.course, this.props.weeks, exceptions)) {
        alert(I18n.t('timeline.blackout_week_created'));
        return false;
      }
    }

    course.day_exceptions = exceptions.join(',');
    course.no_day_exceptions = (_.compact(exceptions).length === 0);
    return CourseActions.updateCourse(course);
  },
  selectWeekday(e, weekday) {
    let weekdays;
    const toPass = this.props.course;
    if (!(toPass.weekdays !== undefined)) {
      toPass.weekdays = '';
      weekdays = [];
    } else {
      weekdays = toPass.weekdays.split('');
    }
    weekdays[weekday] = weekdays[weekday] === '1' ? '0' : '1';
    toPass.weekdays = weekdays.join('');
    return CourseActions.updateCourse(toPass);
  },
  inrange(day) {
    const { course } = this.props;
    if (course.start === undefined) { return false; }
    const start = new Date(course.start);
    const end = new Date(course.end);
    return start < day && day < end;
  },
  render() {
    const modifiers = {
      ['outrange']: day => {
        return !this.inrange(day);
      },
      ['selected']: day => {
        if ((this.props.course.weekdays !== undefined) && this.props.course.weekdays.charAt(day) === '1') {
          return true;
        } else if (day < 8) {
          return false;
        }
        const formatted = moment(day).format('YYYYMMDD');
        const inrange = this.inrange(day);
        let exception = false;
        let weekday = false;
        if (this.props.course.day_exceptions !== undefined) {
          exception = __in__(formatted, this.props.course.day_exceptions.split(','));
        }
        if (this.props.course.weekdays) {
          weekday = this.props.course.weekdays.charAt(moment(day).format('e')) === '1';
        }
        return inrange && ((weekday && !exception) || (!weekday && exception));
      },
      ['highlighted']: day => {
        if (day <= 7) { return false; }
        return this.inrange(day);
      },
      ['bordered']: day => {
        if (day <= 7) { return false; }
        if (!this.props.course.day_exceptions || !this.props.course.weekdays) { return false; }
        const formatted = moment(day).format('YYYYMMDD');
        const inrange = this.inrange(day);
        const exception = __in__(formatted, this.props.course.day_exceptions.split(','));
        const weekday = this.props.course.weekdays.charAt(moment(day).format('e')) === '1';
        return inrange && exception && weekday;
      }
    };

    const editDaysText = I18n.t('courses.calendar.select_meeting_days');
    const editCalendarText = this.props.calendarInstructions;

    let editingDays;
    let editingCalendar;
    if (this.props.editable) {
      if (this.props.shouldShowSteps) {
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


    const onWeekdayClick = this.props.editable ? this.selectWeekday : null;
    const onDayClick = this.props.editable ? this.selectDay : null;

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
              initialMonth={this.state.initialMonth}
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
  }
}
);

export default Calendar;
