import React, { useState, useRef } from 'react';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import DatePicker from '../common/date_picker.jsx';
import Calendar from '../common/calendar.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

const FormPanel = (props) => {
  const [setAnyDatesSelected] = useState(false);
  const [setBlackoutDatesSelected] = useState(false);
  const noDates = useRef(null);

  const setNoBlackoutDatesChecked = () => {
    const { checked } = noDates;
    const toPass = props.course;
    toPass.no_day_exceptions = checked;
    props.updateCourse(toPass);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(props.course, valueKey, value);
    props.updateCourse(updatedCourse);
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
    if (__guard__(props.course.weekdays, x => x.indexOf(1)) >= 0 && (__guard__(props.course.day_exceptions, x1 => x1.length) > 0 || props.course.no_day_exceptions)) {
      return true;
    }
    return false;
  };

  const dateProps = CourseDateUtils.dateProps(props.course);

  const step1 = props.shouldShowSteps ? (
    <h2>
      <span>1.</span>
      {/* eslint-disable-next-line i18next/no-literal-string */}
      <small> Confirm the course`&apos;`s start and end dates.</small>
    </h2>
  ) : (
    // eslint-disable-next-line i18next/no-literal-string
    <p>Confirm the course`&apos;`s start and end dates.</p>
  );

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
            label="Assignment Start"
            date_props={dateProps.timeline_start}
          />
          <DatePicker
            onChange={updateCourseDates}
            value={props.course.timeline_end}
            value_key="timeline_end"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Assignment End"
            date_props={dateProps.timeline_end}
            enabled={Boolean(props.course.start)}
          />
        </div>
      </div>
      <hr />
      <div className="wizard_form course-dates course-dates_step">
        <Calendar
          course={props.course}
          editable={true}
          save={true}
          setAnyDatesSelected={setAnyDatesSelected}
          setBlackoutDatesSelected={setBlackoutDatesSelected}
          calendarInstructions={I18n.t('wizard.calendar_instructions')}
          updateCourse={props.updateCourse}
        />
        <label>
          { I18n.t('I have no class holidays') }
          <input
            type="checkbox"
            onChange={setNoBlackoutDatesChecked}
            ref={(checkbox) => { props.noDates = checkbox; }}
          />
        </label>
      </div>
    </div>
  );

  return (
    <Panel
      {...props}
      saveCourse={saveCourse}
      nextEnabled={nextEnabled}
      raw_options={rawOptions}
      helperText="Select meeting days and holiday dates, then continue."
    />
  );
};

FormPanel.propTypes = {
  course: PropTypes.object.isRequired,
  shouldShowSteps: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired,
  isValid: PropTypes.bool.isRequired,
};

export default FormPanel;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
