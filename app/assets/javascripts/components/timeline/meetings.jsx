import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import CourseLink from '../common/course_link.jsx';
import Calendar from '../common/calendar.jsx';
import Modal from '../common/modal.jsx';
import DatePicker from '../common/date_picker.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { updateCourse, persistCourse } from '../../actions/course_actions';
import { isValid } from '../../selectors';

const Meetings = ({ weeks, course }) => {
  Meetings.propTypes = {
    weeks: PropTypes.array,
    course: PropTypes.object,
    isValid: PropTypes.bool.isRequired,
  };

  const dispatch = useDispatch();
  const valid = useSelector(isValid);

  const updateCourseHandler = (valueKey, value) => {
    const updatedCourse = { ...course, [valueKey]: value };
    dispatch(updateCourse(updatedCourse));
  };

  const updateCourseDatesHandler = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(course, valueKey, value);
    dispatch(updateCourse(updatedCourse));
  };

  const saveCourseHandler = (e) => {
    if (valid) {
      dispatch(persistCourse(course.slug));
    } else {
      e.preventDefault();
      alert(I18n.t('error.form_errors'));
    }
  };

  const updateCheckboxHandler = (e) => {
    updateCourseHandler('no_day_exceptions', e.target.checked);
    updateCourseHandler('day_exceptions', '');
  };

  const saveDisabledClass = (courseObj) => {
    const blackoutDatesSelected = courseObj.day_exceptions && courseObj.day_exceptions.length > 0;
    const anyDatesSelected = courseObj.weekdays && courseObj.weekdays.indexOf(1) >= 0;
    const enable = blackoutDatesSelected || (anyDatesSelected && courseObj.no_day_exceptions);
    return enable ? '' : 'disabled';
  };

  if (!course) {
    return <div />;
  }

  const dateProps = CourseDateUtils.dateProps(course);
  let courseLinkClass = 'dark button ';
  courseLinkClass += saveDisabledClass(course);
  const courseLinkTarget = `/courses/${course.slug}/timeline`;

  return (
    <Modal>
      <div className="wizard__panel active">
        <h3>{I18n.t('timeline.course_dates')}</h3>
        <div className="course-dates__step">
          <p>{I18n.t('timeline.course_dates_instructions')}</p>
          <div className="vertical-form full-width">
            <DatePicker
              onChange={updateCourseDatesHandler}
              value={course.start}
              value_key="start"
              validation={CourseDateUtils.isDateValid}
              editable={true}
              label={I18n.t('timeline.course_start')}
            />
            <DatePicker
              onChange={updateCourseDatesHandler}
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
              onChange={updateCourseDatesHandler}
              value={course.timeline_start}
              value_key="timeline_start"
              editable={true}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_start')}
              date_props={dateProps.timeline_start}
            />
            <DatePicker
              onChange={updateCourseDatesHandler}
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
            weeks={weeks}
            updateCourse={updateCourseHandler}
          />
          <label>
            {I18n.t('timeline.no_class_holidays')}
            <input
              type="checkbox"
              onChange={updateCheckboxHandler}
              checked={course.day_exceptions === '' && course.no_day_exceptions}
            />
          </label>
        </div>
        <div className="wizard__panel__controls">
          <div className="left" />
          <div className="right">
            <CourseLink
              onClick={saveCourseHandler}
              className={courseLinkClass}
              to={courseLinkTarget}
              id="course_cancel"
            >
              {I18n.t('common.done')}
            </CourseLink>
          </div>
        </div>
      </div>
    </Modal>
  );
};

export default Meetings;
