import React, { useRef } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CourseLink from '../common/course_link.jsx';
import Calendar from '../common/calendar.jsx';
import Modal from '../common/modal.jsx';
import DatePicker from '../common/date_picker.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { updateCourse, persistCourse } from '../../actions/course_actions';
import { isValid } from '../../selectors';

const Meetings = (props) => {
  const noDatesRef = useRef();

  const updateCourseHandler = (valueKey, value) => {
    const toPass = props.course;
    toPass[valueKey] = value;
    return props.updateCourse(toPass);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(props.course, valueKey, value);
    return props.updateCourse(updatedCourse);
  };

  const saveCourse = (e) => {
    if (props.isValid) {
      return props.persistCourse(props.course.slug);
    }
    e.preventDefault();
    return alert(I18n.t('error.form_errors'));
  };

  const updateCheckbox = (e) => {
    updateCourseHandler('no_day_exceptions', e.target.checked);
    return updateCourseHandler('day_exceptions', '');
  };

  const saveDisabledClass = (course) => {
    const blackoutDatesSelected = course.day_exceptions && course.day_exceptions.length > 0;
    const anyDatesSelected = course.weekdays && course.weekdays.indexOf(1) >= 0;
    const enable = blackoutDatesSelected || (anyDatesSelected && props.course.no_day_exceptions);
    if (enable) { return ''; }
    return 'disabled';
  };

  const { course } = props;
  if (!course) { return <div />; }

  const dateProps = CourseDateUtils.dateProps(course);
  let courseLinkClass = 'dark button ';
  courseLinkClass += saveDisabledClass(course);
  const courseLinkTarget = `/courses/${course.slug}/timeline`;

  return (
    <Modal >
      <div className="wizard__panel active">
        <h3>{I18n.t('timeline.course_dates')}</h3>
        <div className="course-dates__step">
          <p>{I18n.t('timeline.course_dates_instructions')}</p>
          <div className="vertical-form full-width">
            <DatePicker
              onChange={updateCourseDates}
              value={course.start}
              value_key="start"
              validation={CourseDateUtils.isDateValid}
              editable={true}
              label={I18n.t('timeline.course_start')}
            />
            <DatePicker
              onChange={updateCourseDates}
              value={course.end}
              value_key="end"
              validation={CourseDateUtils.isDateValid}
              editable={true}
              label={I18n.t('timeline.course_end')}
              date_props={dateProps.end}
              enabled={Boolean(course.start)}
            />
          </div>
        </div>
        <hr />
        <div className="course-dates__step">
          <p>{I18n.t('timeline.assignment_dates_instructions')}</p>
          <div className="vertical-form full-width">
            <DatePicker
              onChange={updateCourseDates}
              value={course.timeline_start}
              value_key="timeline_start"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_start')}
              date_props={dateProps.timeline_start}
            />
            <DatePicker
              onChange={updateCourseDates}
              value={course.timeline_end}
              value_key="timeline_end"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_end')}
              date_props={dateProps.timeline_end}
              enabled={Boolean(course.start)}
            />
          </div>
        </div>
        <hr />
        <div className="wizard__form course-dates course-dates__step">
          <Calendar
            course={course}
            save={true}
            editable={true}
            calendarInstructions={I18n.t('courses.course_dates_calendar_instructions')}
            weeks={props.weeks}
            updateCourse={props.updateCourse}
          />
          <label> {I18n.t('timeline.no_class_holidays')}
            <input
              type="checkbox"
              onChange={updateCheckbox}
              ref={noDatesRef}
              checked={props.course.day_exceptions === '' && props.course.no_day_exceptions}
            />
          </label>
        </div>
        <div className="wizard__panel__controls">
          <div className="left" />
          <div className="right">
            <CourseLink
              onClick={saveCourse}
              className={courseLinkClass}
              to={courseLinkTarget}
              id="course_cancel"
            >
              {I18n.t('timeline.done')}
            </CourseLink>
          </div>
        </div>
      </div>
    </Modal>
  );
};

Meetings.propTypes = {
  weeks: PropTypes.array, // Comes indirectly from TimelineHandler
  course: PropTypes.object,
  updateCourse: PropTypes.func.isRequired,
  persistCourse: PropTypes.func.isRequired,
  isValid: PropTypes.bool.isRequired
};

const mapStateToProps = state => ({
  isValid: isValid(state)
});

const mapDispatchToProps = {
  updateCourse,
  persistCourse
};

export default connect(mapStateToProps, mapDispatchToProps)(Meetings);
