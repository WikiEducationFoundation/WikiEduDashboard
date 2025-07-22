import React, { useRef } from 'react';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import DatePicker from '../common/date_picker.jsx';
import Calendar from '../common/calendar.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

const FormPanel = (props) => {
  const noDates = useRef();

  const setNoBlackoutDatesChecked = () => {
    const { checked } = noDates.current;
    const toPass = props.course;
    toPass.no_day_exceptions = checked;
    return props.updateCourse(toPass);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(props.course, valueKey, value);
    return props.updateCourse(updatedCourse);
  };

  const saveCourse = () => {
    if (props.isValid) {
      props.persistCourse(props.course.slug);
      return true;
    }
    alert(I18n.t('error.form_errors'));
    return false;
  };

  const nextEnabled = () => {
    if (__guard__(props.course.weekdays, x => x.indexOf(1)) >= 0
      && (__guard__(props.course.day_exceptions, x1 => x1.length) > 0 || props.course.no_day_exceptions)) {
      return true;
    }
    return false;
  };

  const dateProps = CourseDateUtils.dateProps(props.course);

  const step1 = props.shouldShowSteps
    ? <h2><span>1.</span><small> {I18n.t('wizard.confirm_course_dates')} </small></h2>
    : <p>{I18n.t('wizard.confirm_course_dates')}</p>;

  const rawOptions = (
    <div>
      <div className="course-dates__step">
        {step1}
        <div className="vertical-form full-width">
          <DatePicker
            onChange={updateCourseDates}
            value={props.course.start}
            value_key="start"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Course Start"
          />
          <DatePicker
            onChange={updateCourseDates}
            value={props.course.end}
            value_key="end"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Course End"
            date_props={dateProps.end}
            enabled={Boolean(props.course.start)}
          />
        </div>
      </div>
      <hr />
      <div className="course-dates__step">
        <p>{I18n.t('wizard.assignment_description')}</p>
        <div className="vertical-form full-width">
          <DatePicker
            onChange={updateCourseDates}
            value={props.course.timeline_start}
            value_key="timeline_start"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label={I18n.t('courses.assignment_start')}
            date_props={dateProps.timeline_start}
          />
          <DatePicker
            onChange={updateCourseDates}
            value={props.course.timeline_end}
            value_key="timeline_end"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label={I18n.t('courses.assignment_end')}
            date_props={dateProps.timeline_end}
            enabled={Boolean(props.course.start)}
          />
        </div>
      </div>
      <hr />
      <div className="wizard__form course-dates course-dates__step">
        <Calendar
          course={props.course}
          editable={true}
          save={true}
          calendarInstructions={I18n.t('wizard.calendar_instructions')}
          updateCourse={props.updateCourse}
        />
        <label> {I18n.t('wizard.no_class_holidays')}
          <input
            type="checkbox"
            onChange={setNoBlackoutDatesChecked}
            ref={noDates}
          />
        </label>
      </div>
    </div>
  );

  return (
    <Panel
      {...props}
      raw_options={rawOptions}
      nextEnabled={nextEnabled}
      saveCourse={saveCourse}
      helperText="Select meeting days and holiday dates, then continue."
    />
  );
};

FormPanel.propTypes = {
  course: PropTypes.object.isRequired,
  shouldShowSteps: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired,
  isValid: PropTypes.bool.isRequired
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}

export default FormPanel;
