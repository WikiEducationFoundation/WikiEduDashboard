import React, { useState, useRef } from 'react';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import DatePicker from '../common/date_picker.jsx';
import Calendar from '../common/calendar.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { persistCourse } from '@actions/course_actions';

const FormPanel = ({ course, shouldShowSteps, updateCourse, isValid }) => {
  const [setAnyDatesSelected] = useState(false);
  const [setBlackoutDatesSelected] = useState(false);
  const noDates = useRef(null);

  const setNoBlackoutDatesChecked = () => {
    const { checked } = noDates.current;
    const toPass = { ...course };
    toPass.no_day_exceptions = checked;
    updateCourse(toPass);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(course, valueKey, value);
    updateCourse(updatedCourse);
  };

  const saveCourse = () => {
    if (isValid) {
      // Assuming persistCourse is passed as a prop but not defined here
      persistCourse(course.slug);
      return true;
    }
    alert('Error: Form has errors.');
    return false;
  };

  const nextEnabled = () => {
    return (
      course.weekdays?.indexOf(1) >= 0
      && (course.day_exceptions?.length > 0 || course.no_day_exceptions)
    );
  };

  const dateProps = CourseDateUtils.dateProps(course);

  const step1 = shouldShowSteps ? (
    <h2>
      <span>1.</span>
      {/* eslint-disable-next-line i18next/no-literal-string */}
      <small> Confirm the course’s start and end dates.</small>
    </h2>
  ) : (
    // eslint-disable-next-line i18next/no-literal-string
    <p>Confirm the course’s start and end dates.</p>
  );

  const rawOptions = (
    <div>
      <div className="course-dates__step">
        {step1}
        <div className="vertical-form full-width">
          <DatePicker
            onChange={updateCourseDates}
            value={course.start}
            value_key="start"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Course Start"
          />
          <DatePicker
            onChange={updateCourseDates}
            value={course.end}
            value_key="end"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Course End"
            date_props={dateProps.end}
            enabled={Boolean(course.start)}
          />
        </div>
      </div>
      <hr />
      <div className="course-dates__step">
        {/* eslint-disable-next-line i18next/no-literal-string */}
        <p>Assignment Description</p>
        <div className="vertical-form full-width">
          <DatePicker
            onChange={updateCourseDates}
            value={course.timeline_start}
            value_key="timeline_start"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Assignment Start"
            date_props={dateProps.timeline_start}
          />
          <DatePicker
            onChange={updateCourseDates}
            value={course.timeline_end}
            value_key="timeline_end"
            editable={true}
            validation={CourseDateUtils.isDateValid}
            label="Assignment End"
            date_props={dateProps.timeline_end}
            enabled={Boolean(course.start)}
          />
        </div>
      </div>
      <hr />
      <div className="wizard_form course-dates course-dates_step">
        <Calendar
          course={course}
          editable={true}
          save={true}
          setAnyDatesSelected={setAnyDatesSelected}
          setBlackoutDatesSelected={setBlackoutDatesSelected}
          calendarInstructions="Calendar Instructions"
          updateCourse={updateCourse}
        />
        {/* eslint-disable-next-line i18next/no-literal-string */}
        <label>
          I have no class holidays
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
      course={course}
      panel={{
        title: 'Course Dates', // Changed from 'Course Date'
        options: [],
        error: false,
        type: 0,
        minimum: 1,
      }}
      active={true}
      saveCourse={saveCourse}
      nextEnabled={nextEnabled}
      index={0}
      open_weeks={0}
      raw_options={rawOptions}
      advance={() => {}}
      rewind={() => {}}
      button_text="Next"
      helperText="Select meeting days and holiday dates, then continue."
      summary={false}
      step="Step 1"
      panelCount={1}
      selectWizardOption={() => {}}
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
