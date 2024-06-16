import React, { useState, useRef, useCallback } from 'react';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import DatePicker from '../common/date_picker.jsx';
import Calendar from '../common/calendar.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

const FormPanel = ({ course, shouldShowSteps, updateCourse, isValid, persistCourse }) => {
  const [anyDatesSelected, setAnyDatesSelected] = useState(false);
  const [blackoutDatesSelected, setBlackoutDatesSelected] = useState(false);
  const noDates = useRef(null);
  const setNoBlackoutDatesChecked = useCallback(() => {
    const { checked } = noDates.current;
    const updatedCourse = { ...course, no_day_exceptions: checked };
    updateCourse(updatedCourse);
  }, [course, updateCourse]);

  const updateCourseDates = useCallback((valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(course, valueKey, value);
    updateCourse(updatedCourse);
  }, [course, updateCourse]);

  const saveCourse = useCallback(() => {
    if (!anyDatesSelected) {
      alert('Please select at least one date.');
      return false;
    }

    if (!blackoutDatesSelected) {
      alert('Please select blackout dates.');
      return false;
    }

    if (isValid) {
      persistCourse(course.slug);
      return true;
    }
    alert(I18n.t('error.form_errors'));
    return false;
  }, [anyDatesSelected, blackoutDatesSelected, isValid, persistCourse, course.slug]);

  const nextEnabled = useCallback(() => {
    if (!anyDatesSelected || !blackoutDatesSelected) {
      return false;
    }

    return course.weekdays?.indexOf(1) >= 0 && (course.day_exceptions?.length > 0 || course.no_day_exceptions);
  }, [anyDatesSelected, blackoutDatesSelected, course]);

  const dateProps = CourseDateUtils.dateProps(course);

  const step1 = shouldShowSteps
    ? <h2><span>1.</span><small> Confirm the course’s start and end dates.</small></h2>
    : <p>Confirm the course’s start and end dates.</p>;

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
        <p>{I18n.t('wizard.assignment_description')}</p>
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
          editable={true}
          save={true}
          setAnyDatesSelected={setAnyDatesSelected}
          setBlackoutDatesSelected={setBlackoutDatesSelected}
          calendarInstructions={I18n.t('wizard.calendar_instructions')}
          updateCourse={updateCourse}
        />
        <label> I have no class holidays
          <input type="checkbox" onChange={setNoBlackoutDatesChecked} ref={noDates} />
        </label>
      </div>
    </div>
  );

  return (
    <Panel
      {...{ course, shouldShowSteps, updateCourse, isValid }}
      raw_options={rawOptions}
      nextEnabled={nextEnabled}
      saveCourse={saveCourse}
      helperText={
        anyDatesSelected && blackoutDatesSelected 
          ? 'Select meeting days and holiday dates, then continue.'
          : 'Please select at least one date and blackout dates to continue.'
      }
    />
  );
};

FormPanel.propTypes = {
  course: PropTypes.object.isRequired,
  shouldShowSteps: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired,
  isValid: PropTypes.bool.isRequired,
  persistCourse: PropTypes.func.isRequired,
};

export default FormPanel;
